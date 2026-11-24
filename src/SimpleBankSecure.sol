// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice SEGURO: respeta Checks-Effects-Interactions
contract SimpleBankSecure {
    mapping(address => uint256) public userBalance;

    function deposit() public payable {
        require(msg.value >= 1 ether, "Minimum deposit is 1 ETH");
        userBalance[msg.sender] += msg.value;
    }

    function withdraw() public {
        // 1. Checks
        uint256 amount = userBalance[msg.sender];
        require(amount >= 1 ether, "User has not enough balance");
        require(address(this).balance > 0, "Bank is rekt");

        // 2. Effects
        userBalance[msg.sender] = 0;

        // 3. Interactions
        (bool success,) = msg.sender.call{ value: amount }("");
        require(success, "Fail");
    }

    function totalBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
