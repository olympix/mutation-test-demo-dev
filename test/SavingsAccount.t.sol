// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/SavingsAccount.sol";
import "../src/ReentrancyAttack.sol"; // <-- Add this import

contract SavingsAccountTest is Test {
    SavingsAccount public savingsAccount;
    address public user = address(0x1);
    address public attackerAddress = address(0x2);
    ReentrancyAttack public attacker; // Move declaration to the contract level

    function setUp() public {
        savingsAccount = new SavingsAccount();
        vm.deal(user, 200 ether);


        vm.deal(attackerAddress, 200 ether);

        vm.prank(attackerAddress);
        attacker = new ReentrancyAttack(savingsAccount); // Initialize the attacker here
    }

    function testDeposit() public {
        vm.prank(user);
        savingsAccount.deposit{value: 50 ether}();

        uint256 balance = savingsAccount.balances(user);
        assertEq(balance, 50 ether);
    }

    function testWithdraw() public {
        vm.prank(user);
        savingsAccount.deposit{value: 50 ether}();

        vm.prank(user);
        savingsAccount.withdraw(20 ether);

        uint256 balance = savingsAccount.balances(user);
        assertEq(balance, 31 ether);
    }

    function testTotalDepositsUpdateOnBonus() public {
        // Deposit above threshold
        vm.prank(user);
        savingsAccount.deposit{value: 150 ether}();
        
        uint256 initialTotalDeposits = savingsAccount.totalDeposits();
        
        // Trigger bonus
        vm.prank(user);
        savingsAccount.withdraw(50 ether);
        
        uint256 finalTotalDeposits = savingsAccount.totalDeposits();
        assertEq(finalTotalDeposits, initialTotalDeposits + 1 ether);
    }

    function testMultipleUsersBonusApplication() public {
        address user2 = address(0x3);
        vm.deal(user2, 200 ether);
        
        // Both users deposit above threshold
        vm.prank(user);
        savingsAccount.deposit{value: 150 ether}();
        vm.prank(user2);
        savingsAccount.deposit{value: 150 ether}();
        
        // Both users withdraw to trigger bonus
        vm.prank(user);
        savingsAccount.withdraw(50 ether);
        vm.prank(user2);
        savingsAccount.withdraw(50 ether);
        
        assertEq(savingsAccount.balances(user), 101 ether);
        assertEq(savingsAccount.balances(user2), 101 ether);
    }

    function testLoyaltyBonusAmount() public {
        vm.prank(user);
        savingsAccount.deposit{value: 150 ether}();
        
        uint256 initialBalance = savingsAccount.balances(user);
        
        vm.prank(user);
        savingsAccount.withdraw(50 ether);
        
        uint256 finalBalance = savingsAccount.balances(user);
        assertEq(finalBalance, initialBalance - 50 ether + 1 ether);
    }

    function testMultipleBonusWithdrawals() public {
        // Deposit above threshold
        vm.prank(user);
        savingsAccount.deposit{value: 200 ether}();
        
        // First withdrawal should apply bonus
        vm.prank(user);
        savingsAccount.withdraw(50 ether);
        assertEq(savingsAccount.balances(user), 151 ether, "First withdrawal should apply bonus");
        
        // Second withdrawal should not apply bonus
        vm.prank(user);
        savingsAccount.withdraw(50 ether);
        assertEq(savingsAccount.balances(user), 102 ether, "Second withdrawal should not apply bonus");
        
        // Deposit again to go above threshold
        vm.prank(user);
        savingsAccount.deposit{value: 100 ether}();
        
        // Withdraw again, should still not apply bonus
        vm.prank(user);
        savingsAccount.withdraw(50 ether);
        assertEq(savingsAccount.balances(user), 153 ether, "Bonus should not be applied after initial withdrawal");
    }

    function testMe() public {
        string memory env = vm.envString("TEST_ENV");
        assertEq(env, "true", "Environment variable TEST_ENV should be 'test'"); 
    }
}
