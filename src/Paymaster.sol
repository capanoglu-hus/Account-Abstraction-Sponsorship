// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;
import {BasePaymaster} from "lib/account-abstraction/contracts/core/BasePaymaster.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract Paymaster is BasePaymaster {

    constructor(IEntryPoint i_entryPoint) BasePaymaster(i_entryPoint){} 
    
    /// userOp, userOpHash, ayarlanan gas miktarının gönderilmesi ve onaylanması
    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) internal virtual override returns (bytes memory context, uint256 validationData) {
       (userOp,userOpHash,maxCost);
        // maxCost trans. için ödenecek tutar
        context = ""; //  
       
        //uint48 validUntil = 0 ;// zaman kısıtlaması olmasın diye
        //uint48 validAfter = 0 ;// zaman kısıtlaması olmasın diye
        //bool sigFailed = false; // imza hatası yok işlem onaylanacak
        // onay 
        // aslında bütün kontrolleri yapıp 0 dönüyor 
        // zaten zaman kısıtlaması ve imza onayında sorun olmasın diye direkt 0 diyebiliriz
        //validationData = (sigFailed ? 1 : 0) | (uint256(validUntil) << 1) | (uint256(validAfter) << 49);
        validationData = 0;
    }

    function _postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost,
        uint256 actualUserOpFeePerGas
    ) internal virtual override{
        (mode,context,actualGasCost,actualUserOpFeePerGas);
        //içeride gas hesaplamaları yapıyor
    }

    // erc4337 deploy edildiğinde deploy edinin hesabından entryPoint'e işlem kadar eth geçiyor zaten
    // onu güvenlik olarak alıyor ve trans. olduğunda ödeme direkt entrypointten yapılıyor
    // Entry balance kontrolu
    function getCheckBalance() external view returns(uint256){
        return entryPoint.balanceOf(address(this));
    }
}
