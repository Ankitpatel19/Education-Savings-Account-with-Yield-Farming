// EducationSavingsAccount.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EducationSavingsAccount {
    mapping(address => uint256) public balances;

    // Deposit funds into the account
    function deposit() public payable {
        require(msg.value > 0, "Deposit must be greater than 0");
        balances[msg.sender] += msg.value;   // Increase the sender's balance by the sent Ether
    }

    // Withdraw funds from the account
    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount; // Decrease the sender's balance
        payable(msg.sender).transfer(amount);  // Send the amount to the sender
    }

    // Check the balance of the caller
    function checkBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
}
// YieldFarmingContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TokenContract.sol";

contract YieldFarmingContract {
    TokenContract public token;
    mapping(address => uint256) public stakedBalances;

    // Constructor to initialize the token contract
    constructor(TokenContract _token) {
        token = _token;
    }

    // Stake function to lock tokens in the contract
    function stake(uint256 amount) public {
        require(token.balanceOf(msg.sender) >= amount, "Insufficient token balance");
        token.transferFrom(msg.sender, address(this), amount);
        stakedBalances[msg.sender] += amount;
    }

    // Unstake function to withdraw tokens from the contract
    function unstake(uint256 amount) public {
        require(stakedBalances[msg.sender] >= amount, "Insufficient staked balance");
        stakedBalances[msg.sender] -= amount;
        token.transfer(msg.sender, amount);
    }

    // Function to claim farming rewards based on the staked balance
    function earnRewards() public {
        uint256 rewards = calculateRewards(msg.sender);
        token.transfer(msg.sender, rewards);  // Transfer the calculated rewards
    }

    // Reward calculation logic (returns 10% of staked balance for simplicity)
    function calculateRewards(address user) public view returns (uint256) {
        uint256 stakedBalance = stakedBalances[user];
        return stakedBalance * 10 / 100;  // 10% reward for simplicity
    }
}
// TokenContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenContract {
    mapping(address => uint256) public balances;

    // Function to get the balance of a specific address
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    // Transfer function for transferring tokens
    function transfer(address recipient, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient token balance");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
    }

    // TransferFrom function for allowance-based transfers (for YieldFarmingContract)
    function transferFrom(address sender, address recipient, uint256 amount) public {
        require(balances[sender] >= amount, "Insufficient token balance");
        balances[sender] -= amount;
        balances[recipient] += amount;
    }

    // Function to mint new tokens to an address
    function mint(address to, uint256 amount) public {
        balances[to] += amount;
    }
}
import React, { useState, useEffect } from 'react';
import Web3 from 'web3';
import EducationSavingsAccount from './EducationSavingsAccount.json';
import YieldFarmingContract from './YieldFarmingContract.json';
import TokenContract from './TokenContract.json';

function App() {
    const [account, setAccount] = useState('');
    const [balance, setBalance] = useState(0);
    const [stakedBalance, setStakedBalance] = useState(0);
    const [rewards, setRewards] = useState(0);

    useEffect(() => {
        const init = async () => {
            const web3 = new Web3(window.ethereum);
            await window.ethereum.enable();  // Request access to user's wallet

            const accounts = await web3.eth.getAccounts();
            setAccount(accounts[0]);

            const educationSavingsAccount = new web3.eth.Contract(
                EducationSavingsAccount.abi,
                EducationSavingsAccount.address
            );
            const yieldFarmingContract = new web3.eth.Contract(
                YieldFarmingContract.abi,
                YieldFarmingContract.address
            );
            const tokenContract = new web3.eth.Contract(
                TokenContract.abi,
                TokenContract.address
            );

            const userBalance = await educationSavingsAccount.methods.checkBalance().call({ from: accounts[0] });
            setBalance(web3.utils.fromWei(userBalance, 'ether'));

            const userStakedBalance = await yieldFarmingContract.methods.stakedBalances(accounts[0]).call();
            setStakedBalance(web3.utils.fromWei(userStakedBalance, 'ether'));

            const userRewards = await yieldFarmingContract.methods.calculateRewards(accounts[0]).call();
            setRewards(web3.utils.fromWei(userRewards, 'ether'));
        };

        init();
    }, [account]);

    const handleDeposit = async (amount) => {
        const web3 = new Web3(window.ethereum);
        const educationSavingsAccount = new web3.eth.Contract(
            EducationSavingsAccount.abi,
            EducationSavingsAccount.address
        );

        const amountInWei = web3.utils.toWei(amount, 'ether');
        await educationSavingsAccount.methods.deposit().send({ from: account, value: amountInWei });
    };

    const handleStake = async (amount) => {
        const web3 = new Web3(window.ethereum);
        const yieldFarmingContract = new web3.eth.Contract(
            YieldFarmingContract.abi,
            YieldFarmingContract.address
        );
        const tokenContract = new web3.eth.Contract(
            TokenContract.abi,
            TokenContract.address
        );

        const amountInWei = web3.utils.toWei(amount, 'ether');
        await tokenContract.methods.approve(YieldFarmingContract.address, amountInWei).send({ from: account });
        await yieldFarmingContract.methods.stake(amountInWei).send({ from: account });
    };

    return (
        <div>
            <h1>Education Savings Account with Yield Farming</h1>
            <p>Account: {account}</p>
            <p>Balance: {balance} ETH</p>
            <p>Staked Balance: {stakedBalance} Tokens</p>
            <p>Rewards: {rewards} Tokens</p>

            <button onClick={() => handleDeposit('1')}>Deposit 1 ETH</button>
            <button onClick={() => handleStake('10')}>Stake 10 Tokens</button>
        </div>
    );
}


