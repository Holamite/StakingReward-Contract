// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC20.sol"; // Importing the ERC20 interface for interacting with tokens

contract StakingReward {
    IERC20 public immutable stakingToken; // Immutable variable to store the staking token address
    IERC20 public immutable rewardsToken; // Immutable variable to store the rewards token address

    address public owner; // Address of the contract owner

    uint public duration; // Duration of the staking rewards program
    uint public finishAt; // Timestamp when the rewards program finishes
    uint public updateAt; // Timestamp for the last time rewards were updated
    uint public rewardRate; // Rate at which rewards are distributed
    uint public rewardPerTokenStored; // Rewards per token stored

    mapping (address => uint) userPerTokenPaid; // Mapping to track rewards per token paid to each user
    mapping (address => uint) rewards; // Mapping to track rewards earned by each user

    uint public totalSupply; // Total amount of staked tokens
    mapping (address => uint) balanceOf; // Mapping to track the balance of tokens staked by each user

    modifier onlyOwner {
        require(owner == msg.sender, "Not owner"); // Modifier to restrict access to only the contract owner
        _;
    }

    modifier updateReward(address _acc){
        rewardPerTokenStored = rewardPerToken(); // Update the rewards per token stored
        updateAt = lastTimeRewardApplicable(); // Update the last time rewards were applicable

        if(_acc != address(0)){
            rewards[_acc] = earned(_acc); // Update the rewards earned by the specified account
            userPerTokenPaid[_acc] = rewardPerTokenStored; // Update the rewards per token paid to the specified account
        }
        _;
    }

    constructor(address _stakingToken, address _rewardsToken) {
        owner = msg.sender; // Set the contract owner
        stakingToken = IERC20(_stakingToken); // Initialize the staking token
        rewardsToken = IERC20(_rewardsToken); // Initialize the rewards token
    }

    function setRewardsDuration(uint _duration) external onlyOwner{
        require(finishAt < block.timestamp, "reward duration not finish"); // Ensure the previous rewards program has finished
        duration = _duration; // Set the duration for the next rewards program
    }

    function notifyRewardsAmount(uint _amount) external onlyOwner updateReward(address(0)){
        if (block.timestamp > finishAt){
            rewardRate = _amount / duration; // Calculate the reward rate if the rewards program has finished
        }else{
            uint remainingRewards = rewardRate * (finishAt - block.timestamp);
            rewardRate = (remainingRewards + _amount)/ duration; // Calculate the reward rate for the ongoing rewards program

            require(rewardRate > 0, "reward rate = 0"); // Ensure the reward rate is not zero
            require(rewardRate * duration <= rewardsToken.balanceOf(address(this)), "reward award is greater than balance"); // Ensure sufficient reward balance

            finishAt = block.timestamp + duration; // Set the finish timestamp for the ongoing rewards program
            updateAt = block.timestamp; // Set the update timestamp
        }
    }

    function stake(uint _amount)  external updateReward(msg.sender){
        require(_amount > 0, "amount is equal to 0"); // Ensure the stake amount is greater than zero
        stakingToken.transferFrom(msg.sender, address(this), _amount); // Transfer tokens from the user to the contract
        balanceOf[msg.sender] += _amount; // Update the user's staked balance
        totalSupply += _amount; // Update the total staked supply
    }

    function withdraw(uint _amount)external updateReward(msg.sender){
        require(_amount > 0, "amount is zero"); // Ensure the withdrawal amount is greater than zero
        balanceOf[msg.sender] -= _amount; // Deduct the withdrawal amount from the user's balance
        totalSupply-= _amount; // Deduct the withdrawal amount from the total staked supply
        stakingToken.transfer(msg.sender, _amount); // Transfer tokens back to the user
    }

    function lastTimeRewardApplicable () public view returns(uint){
        return _min(block.timestamp , finishAt); // Get the minimum of the current timestamp and the finish timestamp
    }

    function rewardPerToken()public view returns(uint){
        if(totalSupply == 0){
            return rewardPerTokenStored; // Return the stored rewards per token if the total supply is zero
        }else{
            return rewardPerTokenStored + (rewardRate * 
            (lastTimeRewardApplicable() - updateAt)* 1e18) / totalSupply; // Calculate the rewards per token
        }
    }

    function earned(address _account) public view returns(uint){
        return ((balanceOf[_account] * (rewardPerToken() - userPerTokenPaid[_account])) / 1e18) + rewards[_account]; // Calculate the rewards earned by the user
    }

    function getReward() external updateReward(msg.sender){
       uint reward =  rewards[msg.sender]; // Get the rewards earned by the user
       if(reward > 0){
        rewards[msg.sender] = 0; // Reset the user's rewards to zero
        rewardsToken.transfer(msg.sender, reward); // Transfer the rewards to the user
       }
    }

    function _min (uint x ,uint y) private pure returns(uint){
        return x <= y ? x : y; // Return the minimum of two values
    }
}
