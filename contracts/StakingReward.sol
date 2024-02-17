// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC20.sol";

contract StakingReward {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;


    address public owner;

    uint public duration;
    uint public finishAt;
    uint public updateAt;
    uint public rewardRate;
    uint public rewardPerTokenStored;

    mapping (address => uint) userPerTokenPaid;
    mapping (address => uint) rewards;

    uint public totalSupply;
    mapping (address => uint) balanceOf;

    modifier onlyOwner {
        require(owner == msg.sender, "Not owner");
        _;
    }

    modifier updateReward(address _acc){
        rewardPerTokenStored = rewardPerToken();
        updateAt = lastTimeRewardApplicable();

        if(_acc != address(0)){
            rewards[_acc] = earned(_acc);
            userPerTokenPaid[_acc] = rewardPerTokenStored;
        }
        _;
    }

    constructor(address _stakingToken, address _rewardsToken) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    function setRewardsDuration(uint _duration) external onlyOwner{
        require(finishAt < block.timestamp, "reward duration not finish");
        duration = _duration;
    }

    function notifyRewardsAmount(uint _amount) external onlyOwner updateReward(address(0)){
        if (block.timestamp > finishAt){
            rewardRate = _amount / duration;
        }else{
            uint remainingRewards = rewardRate * (finishAt - block.timestamp);
            rewardRate = (remainingRewards + _amount)/ duration;

            require(rewardRate > 0, "reward rate = 0");
            require(rewardRate * duration <= rewardsToken.balanceOf(address(this)), "reward award is greater than balance");

            finishAt = block.timestamp + duration;
            updateAt = block.timestamp;

        }
    }

    function stake(uint _amount)  external updateReward(msg.sender){
        require(_amount > 0, "amount is equal to 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
    }

    function withdraw(uint _amount)external updateReward(msg.sender){
        require(_amount > 0, "amount is zero");
        balanceOf[msg.sender] -= _amount;
        totalSupply-= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function lastTimeRewardApplicable () public view returns(uint){
        return _min(block.timestamp , finishAt);
    }

    function rewardPerToken()public view returns(uint){
        if(totalSupply == 0){
            return rewardPerTokenStored;
        }else{
            return rewardPerTokenStored + (rewardRate * 
            (lastTimeRewardApplicable() - updateAt)* 1e18) / totalSupply;
        }
    }

    function earned(address _account) public view returns(uint){
        return ((balanceOf[_account] * (rewardPerToken() - userPerTokenPaid[_account])) / 1e18) + rewards[_account];
    }

    function getReward() external updateReward(msg.sender){
       uint reward =  rewards[msg.sender];
       if(reward > 0){
        rewards[msg.sender] = 0;
        rewardsToken.transfer(msg.sender, reward);
       }
    }

    function _min (uint x ,uint y) private pure returns(uint){
        return x <= y ? x : y;
    }
}