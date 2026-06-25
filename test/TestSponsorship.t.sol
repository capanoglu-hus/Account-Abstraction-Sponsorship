pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {SimpleAccount} from "../src/SimpleAccount.sol";
import {SimpleAccountFactory} from "../src/SimpleAccountFactory.sol";
import {Paymaster} from "../src/Paymaster.sol";
import {TestToken} from "../src/TestToken.sol";
import {DeploySimpleAccount} from "../script/DeploySimpleAccount.s.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {console} from "forge-std/console.sol";

contract TestSponsorship is Test {
    DeploySimpleAccount deployer;
    SimpleAccountFactory factory;
    EntryPoint entrypointContract;
    Paymaster paymaster;
    TestToken token;
    address depAddress;

    // set up()
    function setUp() public {
        deployer = new DeploySimpleAccount();
        DeploySimpleAccount.DeployConfig memory config = deployer.run();
        factory = config.factory;
        paymaster = config.paymaster;
        token = config.token;
        depAddress = config.depAddress;
        entrypointContract = config.entrypointContract;
    }

    // a wallet -yeni sıfır eth bulunan cüzdan oluşturma
    function testNewWalletCreate() public {
        // arrange
        address newAddress = makeAddr("new");
        uint256 salt = 0;
        address entry = address(entrypointContract); //factory.sender() // entry'yi deploy eden adrese ayarladık
        // act

        // yeni adresin oluşması ve beklenenle eşleşmesi-Doğmamış Çocuğa Kimlik Çıkarmak

        address hesaplanan = factory.getAddress(newAddress, salt); // böyle bir adres yok sadece hesaplama
        vm.prank(entry); // bundan sonra entry gibi
        SimpleAccount newWallet = factory.createAccount(newAddress, salt);

        //assert
        assertEq(address(newWallet), hesaplanan);
        assertEq(newWallet.owner(), newAddress);
        vm.stopPrank();
    }

    function testNewWalletCheckZeroBalance() public {
        // arrange
        address newAddress = makeAddr("new");
        uint256 salt = 0;
        address entry = address(entrypointContract); // entry'yi deploy eden adrese ayarladık

        // act
        vm.prank(entry); // bundan sonra entry gibi
        SimpleAccount newWallet = factory.createAccount(newAddress, salt);

        //assert
        assertEq(address(newWallet).balance, 0);
    }

    // b wallet -normal cüzdan oluşturma
    function testBasicWallet() public {
        address newAddress = makeAddr("new");
        uint256 bakiye = token.balanceOf(address(newAddress));
        assertEq(address(newAddress).balance, 0);
        assertEq(bakiye, 0);
    }

    // sponsor cüzdanı oluşturma -- eth yükleme
    function testSponsorshipWallet() public {
        address sponsor = makeAddr("sponsor");
        vm.deal(sponsor, 50 ether);
        assertEq(sponsor.balance, 50 ether);
        // entryPointte depozit yatırması
        vm.startBroadcast(sponsor);
        entrypointContract.depositTo{value: 20 ether}(address(paymaster));
        vm.stopBroadcast();
        assertEq(sponsor.balance, 30 ether);
    }

    // testToken mint et - a wallet send
    function testMintAWallet() public {
        //arrange
        address newAddress = makeAddr("new");
        uint256 salt = 0;
        address entry = address(entrypointContract); // entry'yi deploy eden adrese ayarladık
        //act
        vm.prank(entry); // bundan sonra entry gibi
        SimpleAccount newWallet = factory.createAccount(newAddress, salt);
        uint256 mintMiktari = 100 * 10 ** 6;
        token.mint(address(newWallet), mintMiktari);
        uint256 bakiye = token.balanceOf(address(newWallet));
        //assert
        assertEq(bakiye, mintMiktari);
    }

    // a wallet-> b wallet -- gas sponsor wallet
    function testSponsorTransfer() public {
        // arrange
        uint256 aPrivateKey = 0xA11CE; // İstediğin herhangi bir sayı olabilir
        address aAddress = vm.addr(aPrivateKey); // Bu şifreye ait cüzdan adresi
        vm.deal(aAddress, 0);
        address bAddress = makeAddr("b");
        address sponsor = makeAddr("sponsor");
        vm.deal(sponsor, 50 ether);
        uint256 salt = 0;
        address entry = address(entrypointContract); // entry'yi deploy eden adrese ayarladık

        // act

        vm.prank(entry); // bundan sonra entry gibi
        SimpleAccount aWallet = factory.createAccount(aAddress, salt);
        uint256 mintMiktari = 100 * 10 ** 6;
        token.mint(address(aWallet), mintMiktari);
        uint256 bakiye = token.balanceOf(address(aWallet));
        //işlemi güvenliği için
        vm.startBroadcast(sponsor);
        entrypointContract.depositTo{value: 20 ether}(address(paymaster));
        vm.stopBroadcast();

        assertEq(bakiye, mintMiktari);
        // token transferi -- call data
        uint256 transferMiktari = 40 * 10 ** 6;
        // token transfer datası
        bytes memory tokenTransferData = abi.encodeWithSelector(token.transfer.selector, bAddress, transferMiktari);
        // simpleAccount execute()
        bytes memory executeCallData =
            abi.encodeWithSelector(SimpleAccount.execute.selector, address(token), 0, tokenTransferData);

        //PackedUserOperation
        PackedUserOperation memory userOp;
        userOp.sender = address(aWallet);
        userOp.nonce = entrypointContract.getNonce(address(aWallet), 0);
        userOp.initCode = bytes(""); //-- cüzdan deploy edildi
        userOp.callData = executeCallData;

        // gas limit ayarları
        uint128 verificationGasLimit = 5000000;
        uint128 callGasLimit = 5000000;
        userOp.accountGasLimits = bytes32((uint256(verificationGasLimit) << 128) | callGasLimit);
        userOp.preVerificationGas = 500000;
        uint128 maxPriorityFeePerGas = 2 gwei;
        uint128 maxFeePerGas = 2 gwei;
        userOp.gasFees = bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas);
        uint128 paymasterVerificationGasLimit = 1000000;
        uint128 paymasterPostOpGasLimit = 1000000;
        // sponsor yani paymaster ödemesi
        userOp.paymasterAndData =
            abi.encodePacked(address(paymaster), paymasterVerificationGasLimit, paymasterPostOpGasLimit);

        // işlemi imzalama
        bytes32 userOpHash = entrypointContract.getUserOpHash(userOp);
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", userOpHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(aPrivateKey, ethSignedMessageHash);
        userOp.signature = abi.encodePacked(r, s, v);

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOp;

        // fake bundler yaratma
        vm.stopPrank();
        address bundler = makeAddr("bundler");
        vm.deal(bundler, 10 ether);
        // ödemeyi ağa bundler yapıyor
        vm.prank(bundler, bundler);
        entrypointContract.handleOps(ops, payable(bundler));

        //assert
        assertEq(token.balanceOf(address(aWallet)), 60 * 10 ** 6);
        assertEq(token.balanceOf(address(bAddress)), transferMiktari);
        assertEq(aAddress.balance, 0);
        console.log("-----------------------------------------");
        console.log("Transfer basarili ");
        console.log("A Cuzdaninin Kalan Bakiyesi :", token.balanceOf(address(aWallet)));
        console.log("B Adresinin Yeni Bakiyesi    :", token.balanceOf(bAddress));
        console.log("Sponsorun Turnike Bakiyesi  :", paymaster.getCheckBalance());
        console.log("Sponsorun Turnike ADRES  :", address(sponsor));
        console.log("-----------------------------------------");
    }
    //  transfer verify()
}
