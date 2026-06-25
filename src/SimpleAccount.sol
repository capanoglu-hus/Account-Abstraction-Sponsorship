// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;
import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract SimpleAccount is IAccount, Ownable {
    
    error SimpleAccount__NotFromEntrypoint();
    error SimpleAccount__NotFromEntrypointOrOwner();
    error SimpleAccount__CallFailed(bytes);
    error SimpleAccount__AlreadyInitialized();
    
    IEntryPoint private immutable i_entryPoint;
    bool private i_initialized;

    modifier requireFromEntryPoint() {
        if(msg.sender != address(i_entryPoint)){
            revert SimpleAccount__NotFromEntrypoint();
        }
        _;
    }

    modifier requireFromEntryPointOrOwner() {
        if(msg.sender != address(i_entryPoint) && msg.sender != owner()){
            revert SimpleAccount__NotFromEntrypointOrOwner();
        }
        _;
    }

    constructor(IEntryPoint entryPoint) Ownable(msg.sender){
        i_entryPoint = entryPoint;
    } // söz. sahibi kim olursa söz. onaylayacak kişi o 


    function initialize(address expectedOwner) public {
        if (i_initialized) {
            revert SimpleAccount__AlreadyInitialized();
        }
        i_initialized = true;
        
        // Cüzdanın gerçek sahibini yazıyoruz
        _transferOwnership(expectedOwner); 
    }

    /**
     * bu fonk. ile kont. tamamnen ödeme alabilcek 
     */
    receive() external payable {}

    // on-chainde çalışır 
    /**
     * dest-> token adresi
     * value -> gönderilecek değer , eth içim
     * funct.data -> işlem bilgileri
     */
    function execute(address dest, uint256 value, bytes calldata functionData) external requireFromEntryPointOrOwner {
        (bool success, bytes memory result) = dest.call{value:value}(functionData);
        if(!success){
            revert SimpleAccount__CallFailed(result);
        }   
    }






    
    /* kullanıcıyı doğrulayacak
    userOp --> kullanıcı bil. tutan 
    address sender; --> Simple Acoount 
    uint256 nonce; --> nonce
    bytes initCode; -->
    bytes callData; --> koşul işlemleri transfer falan 
    bytes32 accountGasLimits; -->
    uint256 preVerificationGas; -->
    bytes32 gasFees; -->
    bytes paymasterAndData; --> payMaster ın ödeyeceği veri
    bytes signature; --> imzalma 

    userOpHash --> kullanıcı imza iş.
    missingAccountFunds --> entrypointe min transfer tutar-- cağrıyı yapabilmek için -- min tutar
     */
   function validateUserOp
      (PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
      external requireFromEntryPoint returns (uint256 validationData){
       validationData = _validateSignature(userOp, userOpHash);
       //_validateNonce()
       _payPrefund(missingAccountFunds);
      }

    // EIP-191 imzalanmış hash
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash )
    internal
    view
    returns(uint256 validationData)
    {
        //imzalanmış mesaj hash 
        bytes32 ethSignerMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash); // eth imzalamadan yararlanma
        address signer = ECDSA.recover(ethSignerMessageHash,userOp.signature); // hash ve imza tutuyor mu 
        if(signer != owner()){ // imza owner la aynı mı 
            return SIG_VALIDATION_FAILED;
        } 
        return SIG_VALIDATION_SUCCESS;
    }

    function _payPrefund( uint256 missingAccountFunds) internal {
        if(missingAccountFunds !=0 ){
            (bool success,) = payable(msg.sender).call{value:missingAccountFunds,gas:type(uint256).max}("");
            (success);

        }
    }
     /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/
    function getEntryPoint() external view returns (address) {
        return address(i_entryPoint);
    }


}