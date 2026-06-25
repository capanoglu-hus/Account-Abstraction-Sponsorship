
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("UsdtTest", "USDX") {
        _mint(msg.sender, initialSupply);
    }
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
    function decimals() public view virtual override returns (uint8) {
  return 6;
}
}