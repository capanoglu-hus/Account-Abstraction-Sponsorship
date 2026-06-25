pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {SimpleAccount} from "../src/SimpleAccount.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {SimpleAccountFactory} from "../src/SimpleAccountFactory.sol";
import {Paymaster} from "../src/Paymaster.sol";
import {TestToken} from "../src/TestToken.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";
import {console} from "forge-std/console.sol";


contract DeploySimpleAccount is Script {
   struct DeployConfig {
    EntryPoint entrypointContract;
    SimpleAccountFactory factory;
    Paymaster paymaster;
    TestToken token;
    address depAddress;
   }

   function run() external returns (DeployConfig memory){
    address deployer = msg.sender;
  
    if(block.chainid == 11155111){
        // resmi entryPoint adresi
        address sepoliaEntry = vm.envAddress("SEPOLIA_EntryPoint");
        vm.startBroadcast(deployer);
        // create wallet için 
        SimpleAccountFactory factory = new SimpleAccountFactory(IEntryPoint(sepoliaEntry));
        // sponsor - depozit 
        Paymaster paymaster = new Paymaster(IEntryPoint(sepoliaEntry));
        TestToken token = new TestToken(1000 * 10**6);
        // her şeyden önce depoziti göndermeli
        // transfer olacak için entrypointer bu adrese bağlı deposit var mı ? bakar 
        IEntryPoint(sepoliaEntry).depositTo{value: 0.5 ether}(address(paymaster));
        vm.stopBroadcast();
        return DeployConfig({
                entrypointContract: EntryPoint(payable(sepoliaEntry)),
                factory: factory,
                paymaster: paymaster,
                token: token,
                depAddress: deployer
        });
        
    } else {
        vm.startBroadcast(deployer);
        // 1. EntryPoint deploy
        EntryPoint entrypoint = new EntryPoint();
        //2. factory() -- getadress
        SimpleAccountFactory factory = new SimpleAccountFactory(IEntryPoint(address(entrypoint)));
        // sponsorship
        Paymaster paymaster = new Paymaster(IEntryPoint(address(entrypoint)));
        // test token deploy
        TestToken token = new TestToken(1000 * 10**6);
        // çekilecek eth için -- entryPointer'a depozit verme 
        IEntryPoint(entrypoint).depositTo{value: 2 ether}(address(paymaster));
        vm.stopBroadcast();

        return DeployConfig({
                entrypointContract: entrypoint,
                factory: factory,
                paymaster: paymaster,
                token: token,
                depAddress: deployer
            });
    }
    }
    
  
}