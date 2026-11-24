// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice VULNERABLE: envía el ETH antes de actualizar el estado (rompe CEI)
contract SimpleBank {
    mapping(address => uint256) public userBalance;

    function deposit() public payable {
        require(msg.value >= 1 ether, "Minimum deposit is 1 ETH");
        userBalance[msg.sender] += msg.value;
    }

    function withdraw() public {
        // 1. Checks
        require(userBalance[msg.sender] >= 1 ether, "User has not enough balance");
        require(address(this).balance > 0, "Bank is rekt");

        // 3. Interactions (demasiado pronto)
        (bool success,) = msg.sender.call{ value: userBalance[msg.sender] }("");
        require(success, "Fail");

        // 2. Effects (demasiado tarde)
        userBalance[msg.sender] = 0;
    }

    function totalBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
