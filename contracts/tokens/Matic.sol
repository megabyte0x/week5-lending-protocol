// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MATIC is ERC20, Ownable {
    constructor() ERC20("MATIC", "MATIC") {}

    function mint(uint256 _amount) public {
        _mint(msg.sender, _amount);
    }
}
