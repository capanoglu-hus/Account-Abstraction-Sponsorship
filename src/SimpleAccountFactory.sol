// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {SimpleAccount} from "./SimpleAccount.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract SimpleAccountFactory {
    SimpleAccount public immutable account;
    IEntryPoint public immutable entryPoint;

    // error NotSenderCreator(address msgSender, address entity, address senderCreator);

    constructor(IEntryPoint _entryPoint) {
        entryPoint = _entryPoint;
        account = new SimpleAccount(_entryPoint);
        /* account = new SimpleAccount(IEntryPoint(address(_entryPoint)));
        sender = _entryPoint.senderCreator();*/
    }

    // yeni wallet oluşturma - kont.depoly edenin bilgisiyle
    // salt 0
    function createAccount(address owner, uint256 salt) public returns (SimpleAccount ret) {
        /* if(msg.sender != address(sender)){
            revert NotSenderCreator(msg.sender,address(this),address(sender));

        }*/

        address addr = getAddress(owner, salt);

        uint256 codeSize = addr.code.length;
        if (codeSize > 0) {
            return SimpleAccount(payable(addr));
        }
        //Universal Upgradeable Proxy Standard- güncellemeler olduğunda yeniden kullanılabilir
        ERC1967Proxy proxy =
            new ERC1967Proxy{salt: bytes32(salt)}(address(account), abi.encodeCall(SimpleAccount.initialize, (owner)));
        return SimpleAccount(payable(address(proxy)));
    }

    function getAddress(address owner, uint256 salt) public view virtual returns (address) {
        bytes memory initArgs = abi.encode(address(account), abi.encodeCall(SimpleAccount.initialize, (owner)));

        bytes32 bytecodeHash = keccak256(abi.encodePacked(type(ERC1967Proxy).creationCode, initArgs));
        return Create2.computeAddress(bytes32(salt), bytecodeHash);
    }
}
