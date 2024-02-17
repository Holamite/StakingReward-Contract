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

    constructor(address _stakingToken, address _rewardsToken) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    function setRewardsDuration(uint _duration) external onlyOwner{
        require(finishAt < block.timestamp, "reward duration not finish");
        duration = _duration;
    }

    function notifyRewardsAmount(uint _amount) external{
        
    }

    function stake()  external {
        
    }

    function withdraw()external{

    }

    function earned(address _account) external view returns(uint){

    }

    function getReward() external {

    }
}