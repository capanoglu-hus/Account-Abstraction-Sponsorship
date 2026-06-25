pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {SimpleAccount} from "../src/SimpleAccount.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {SimpleAccountFactory} from "../src/SimpleAccountFactory.sol";
import {Paymaster} from "../src/Paymaster.sol";
import {TestToken} from "../src/TestToken.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";

contract RunSponsorship is Script {
    function run() external {
        // arrange - hazırlık
        // Sepolia ağında deploy edilen contract's
        address sepoliaEntryPoint = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;
        address simpleFactory = 0x8B15cA3e809aFae4039aF05F6D7Eb117e056C5bE;
        address paymaster = 0xB12C53F7Ab00897Cb8990afbEFb239A418aBea4d;
        address testToken = 0x759f62A65f5A2dEb8Afe344504200156FfAA6528;

        // owner bilgileri
        uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY");
        address ownerAddress = vm.addr(ownerPrivateKey);
        vm.startBroadcast(ownerPrivateKey);
        // yeni B cüzdanı oluşturma 
        uint256 bWalletPrivateKey = uint256(keccak256(abi.encodePacked("bWalletPrivateKey")));
        address bWalletAddress = vm.addr(bWalletPrivateKey);
        // contrat-ayarlama
        IEntryPoint entryPoint = IEntryPoint(sepoliaEntryPoint);
        SimpleAccountFactory factory = SimpleAccountFactory(simpleFactory);
        TestToken token = TestToken(testToken);

        // wallet oluşturma - önceden mat. hesaplarıyla biliyoruz
        address aWalletAdress = factory.getAddress(ownerAddress,0);
        console.log(" A wallet adres : " ,aWalletAdress );

        // Act - eylem
        
        if(aWalletAdress.code.length == 0){
            console.log("Wallet olusturuluyor");
            factory.createAccount(ownerAddress,0);
        }

        token.mint(aWalletAdress,50 * 10**6); // 50
        console.log("Wallet'a token mint");

        // gas harmacaları artarsa diye 
        entryPoint.depositTo{value: 0.2 ether}(address(paymaster));
        console.log("Paymaster'a EntryPoint uzerinden ek deposit yukleniyor...");
        vm.stopBroadcast();
        // wallet balance kontrolu
        uint256 aWalletIlkBakiye = token.balanceOf(aWalletAdress);
        uint256 bWalletIlkBakiye = token.balanceOf(bWalletAddress);

        console.log("Akilli Cuzdan (A) ilk Token :", aWalletIlkBakiye / 10**6, "TOKEN");
        console.log("Alici Cuzdan  (B) ilk Token  :", bWalletIlkBakiye / 10**6, "TOKEN");
    
        // Paymaster hazırlığı
        // transfer - alıcı- miktar
        bytes memory tokenTransferData = abi.encodeWithSelector(token.transfer.selector, bWalletAddress, 10 * 10**6 );
        // callData ile işlemi off-chainde hazırlıyor 
        bytes memory executeCallData = abi.encodeWithSelector(SimpleAccount.execute.selector,token,0,tokenTransferData);

        // UserOperation oluşturma
        PackedUserOperation memory userOp;
        userOp.sender = aWalletAdress;
        userOp.nonce = entryPoint.getNonce(aWalletAdress,0);
        userOp.initCode = bytes(""); // cüzdan oluşturulması 
        userOp.callData = executeCallData;
        // gas ayarları
        uint128 verificationGasLimit = 200000; 
        uint128 callGasLimit = 200000;         
        userOp.accountGasLimits = bytes32((uint256(verificationGasLimit) << 128) | callGasLimit);
        userOp.preVerificationGas = 100000;
        userOp.gasFees = bytes32((uint256(3 gwei) << 128) | 3 gwei);
        uint128 paymasterVerificationGasLimit = 200000;
        uint128 paymasterPostOpGasLimit = 100000;
        //sponsor ödeme ayarları
        // address, gas ,gas  
        userOp.paymasterAndData = abi.encodePacked(
            address(paymaster), 
            uint128(paymasterVerificationGasLimit), 
            uint128(paymasterPostOpGasLimit));

        //imzalama
        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", userOpHash)
        );
        (uint8 v , bytes32 r , bytes32 s) = vm.sign(ownerPrivateKey,ethSignedMessageHash);
        userOp.signature = abi.encodePacked(r,s,v);

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOp;
        console.log("PackedUserOperation sepolia send");
        
        // bundler gibi davranıp sepoliaya gönderme 
        uint256 bundlerPrivateKey = vm.envUint("BUNDLER_PRIVATE_KEY");
        address bundlerAddress = vm.addr(bundlerPrivateKey);
        bytes memory data = abi.encodeWithSelector(
            entryPoint.handleOps.selector, //işlem
            ops, // gön. data 
            payable(bundlerAddress) // ödemeyi ağa yapacak address 
        );
        vm.startBroadcast(bundlerPrivateKey);
        (bool success, bytes memory returnData) = address(entryPoint).call{gas: 10000000}(data);
        
        if (!success) {
            // Eğer bir hata oluşursa ham hata verisini (hex) loglayarak terminale basıyoruz
            console.log("Low-level call failed!");
            if (returnData.length > 0) {
                revert(string(returnData));
            } else {
                revert("Raw call reverted with no reason");
            }
        }
        
        vm.stopBroadcast();

        console.log("Transfer sepolia aginda..");

        //Assert - Doğrulama
        uint256 aWalletSonBakiye = token.balanceOf(aWalletAdress);
        uint256 bWalletSonBakiye = token.balanceOf(bWalletAddress);
        console.log("wallet code:", aWalletAdress.code.length);
        console.log("nonce:", entryPoint.getNonce(aWalletAdress,0));
        console.log("deposit:", entryPoint.balanceOf(paymaster));
        console.logBytes32(userOp.accountGasLimits);
        console.logBytes(userOp.paymasterAndData);
        console.log("Akilli Cuzdan (A) Kalan Token :", aWalletSonBakiye / 10**6, "TOKEN");
        console.log("Alici Cuzdan  (B) Yeni Bakiye  :", bWalletSonBakiye / 10**6, "TOKEN");
    }
  
} 