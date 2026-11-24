// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { SimpleBank } from "../src/SimpleBank.sol";
import { SimpleBankSecure } from "../src/SimpleBankSecure.sol";
import { Attacker } from "../src/Attacker.sol";

contract ReentrancyTest is Test {
    SimpleBank public vulnerable;
    SimpleBankSecure public secure;
    Attacker public attackerVuln;
    Attacker public attackerSecure;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public hacker = makeAddr("hacker");

    function setUp() public {
        vulnerable = new SimpleBank();
        secure = new SimpleBankSecure();
        attackerVuln = new Attacker(address(vulnerable));
        attackerSecure = new Attacker(address(secure));

        vm.deal(alice, 40 ether);
        vm.deal(bob, 40 ether);
        vm.deal(hacker, 10 ether);

        // Usuarios honestos: 40 ETH en cada banco
        vm.startPrank(alice);
        vulnerable.deposit{ value: 20 ether }();
        secure.deposit{ value: 20 ether }();
        vm.stopPrank();

        vm.startPrank(bob);
        vulnerable.deposit{ value: 20 ether }();
        secure.deposit{ value: 20 ether }();
        vm.stopPrank();
    }

    function test_HonestUserCanWithdraw() public {
        vm.prank(alice);
        vulnerable.withdraw();

        assertEq(vulnerable.userBalance(alice), 0);
        assertEq(alice.balance, 20 ether);
    }

    function test_DepositBelowMinimumReverts() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectRevert(bytes("Minimum deposit is 1 ETH"));
        vulnerable.deposit{ value: 0.5 ether }();
    }

    function test_AttackDrainsVulnerableBank() public {
        vm.prank(hacker);
        attackerVuln.attack{ value: 10 ether }();

        assertEq(address(vulnerable).balance, 0);
        assertEq(address(attackerVuln).balance, 50 ether);
    }

    function test_SecureBankBlocksReentrancy() public {
        vm.prank(hacker);
        vm.expectRevert(bytes("Fail"));
        attackerSecure.attack{ value: 10 ether }();

        assertEq(address(secure).balance, 40 ether);
    }

    function testFuzz_SecureDepositAndWithdraw(uint256 amount) public {
        amount = bound(amount, 1 ether, 1000 ether);
        address user = makeAddr("fuzzUser");
        vm.deal(user, amount);

        vm.startPrank(user);
        secure.deposit{ value: amount }();
        secure.withdraw();
        vm.stopPrank();

        assertEq(user.balance, amount);
        assertEq(secure.userBalance(user), 0);
    }
}
