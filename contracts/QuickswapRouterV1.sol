//SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import {UniswapV2Router02} from "./UniswapV2Router02.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import {IDragonLair} from "./interfaces/IDragonLair.sol";
import {SafeMath} from "./libraries/SafeMath.sol";
import {IStakingRewards} from "./interfaces/IStakingRewards.sol";


struct Staker {
    uint256 balance;
    uint256 userRewardPerTokenPaid;
    uint256 reward;
}

struct Staking {
    uint256 periodFinish;
    uint256 lastUpdateTime;
    uint256 rewardRate;    
    uint256 rewardPerTokenStored;
    uint256 totalSupply;
    // staker => staker info    
    mapping(address => Staker) stakers;    
}


struct AppStorage {
    address owner;
    mapping(address => Staking) staking;

}

// UniswapV2Router02 constructor args:  constructor(address _factory, address _WETH)
contract QuickswapRouterV1 is UniswapV2Router02(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32, 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270) {
    AppStorage s;

    using SafeMath for uint;

    // address constant public QUICKSWAP_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;   
    IDragonLair constant public DRAGON_LAIR = IDragonLair(0xf28164A485B0B2C90639E47b0f377b4a438a16B1);
    address constant public QUICK = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;

    constructor(address _owner) {
        s.owner = _owner;
        IERC20(QUICK).approve(address(DRAGON_LAIR), type(uint256).max);
    }

    function enterDragonLair(uint256 _quickAmount) external {

    }

    function enterDragonLairAndSyrup(address[] calldata _syrupPools, uint256[] calldata _quickAmounts) external {
      require(_syrupPools.length == _quickAmounts.length, "Input lengths do not match");
      uint256 totalQuickAmount;
      for(uint i; i < _quickAmounts.length; i++) {        
          totalQuickAmount = SafeMath.add(_quickAmounts[i], totalQuickAmount);
          //IStakingRewards(_syrupPools[i]).stake(msg.sender, DRAGON_LAIR.QUICKForDQUICK(_quickAmounts[i]));                        
      }
      TransferHelper.safeTransferFrom(QUICK, msg.sender, address(this), totalQuickAmount);
      DRAGON_LAIR.enter(totalQuickAmount);
    }

    // staking functions

    function totalSupply(address _rewardToken) external view returns (uint256) {
          return s.staking[_rewardToken].totalSupply;
    }  

    function balanceOf(address _rewardToken, address _account) external view returns (uint256) {
        return s.staking[_rewardToken].stakers[_account].balance;
    }


    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function lastTimeRewardApplicable(address _rewardToken) public view returns (uint256) {     
        return min(block.timestamp, s.staking[_rewardToken].periodFinish);
    }


    function rewardPerToken(address _rewardToken) public view returns (uint256) {
        Staking storage staking = s.staking[_rewardToken];
        if (staking.totalSupply == 0) {
            return staking.rewardPerTokenStored;
        }
        else {
            return
                staking.rewardPerTokenStored.add(
                    lastTimeRewardApplicable(_rewardToken).sub(staking.lastUpdateTime).mul(staking.rewardRate).mul(1e18).div(staking.totalSupply)
                );
        }
    }

    function earned(address _rewardToken, address _account) public view returns (uint256) {
        Staking storage staking = s.staking[_rewardToken];
        Staker storage staker = staking.stakers[_account];
        return staker.balance.mul(rewardPerToken(_rewardToken).sub(staker.userRewardPerTokenPaid)).div(1e18).add(staker.reward);        
    }

    struct StakeInput {
        address rewardToken;
        uint256 amount;        
    }

    function stake(StakeInput[] calldata _stakes) external {
        for(uint256 i; i < _stakes.length; i++) {
            StakeInput calldata stakeInput = _stakes[i];
            require(stakeInput.amount > 0, "Cannot stake 0");
            updateReward(stakeInput.rewardToken, msg.sender);
            Staking storage staking = s.staking[stakeInput.rewardToken];
            staking.totalSupply = staking.totalSupply.add(stakeInput.amount);
            Staker storage staker = staking.stakers[msg.sender];
            staker.balance = staker.balance.add(stakeInput.amount);
            TransferHelper.safeTransferFrom(address(DRAGON_LAIR), msg.sender, address(this), stakeInput.amount);
            emit Staked(stakeInput.rewardToken, msg.sender, stakeInput.amount);
        }        
    }   

    function withdraw(StakeInput[] calldata _stakes) external {
        for(uint256 i; i < _stakes.length; i++) {
            StakeInput calldata stakeInput = _stakes[i];
            require(stakeInput.amount > 0, "Cannot withdraw 0");
            updateReward(stakeInput.rewardToken, msg.sender);
            Staking storage staking = s.staking[stakeInput.rewardToken];
            staking.totalSupply = staking.totalSupply.sub(stakeInput.amount);
            Staker storage staker = staking.stakers[msg.sender];
            staker.balance = staker.balance.sub(stakeInput.amount);
            TransferHelper.safeTransfer(address(DRAGON_LAIR), msg.sender, stakeInput.amount);
            emit Withdrawn(stakeInput.rewardToken, msg.sender, stakeInput.amount);
        }        
    }

    function withdraw(address[] calldata _rewardTokens) public {
        for(uint256 i; i < _rewardTokens.length; i++) {
            address rewardToken = _rewardTokens[i];            
            updateReward(rewardToken, msg.sender);
            Staking storage staking = s.staking[rewardToken];
            Staker storage staker = staking.stakers[msg.sender];
            uint256 balance = staker.balance;
            staking.totalSupply = staking.totalSupply.sub(balance);            
            staker.balance = 0;
            TransferHelper.safeTransfer(address(DRAGON_LAIR), msg.sender, balance);
            emit Withdrawn(rewardToken, msg.sender, balance);
        }        
    }

    function getRewards(address[] calldata _rewardTokens) public {
        for(uint256 i; i < _rewardTokens.length; i++) {
            address rewardToken = _rewardTokens[i];
            updateReward(rewardToken, msg.sender);
            Staker storage staker = s.staking[rewardToken].stakers[msg.sender];
            uint256 reward = staker.reward;
            if (reward > 0) {
                staker.reward = 0;
                TransferHelper.safeTransfer(rewardToken, msg.sender, reward);                
                emit RewardPaid(rewardToken, msg.sender, reward);
            }
        }
        
    }

    function exit(address[] calldata _rewardTokens) external {                    
        for(uint256 i; i < _rewardTokens.length; i++) {
            address rewardToken = _rewardTokens[i];
            updateReward(rewardToken, msg.sender);
            Staking storage staking = s.staking[rewardToken];
            Staker storage staker = staking.stakers[msg.sender];
            uint256 balance = staker.balance;
            staking.totalSupply = staking.totalSupply.sub(balance);            
            staker.balance = 0;
            TransferHelper.safeTransfer(address(DRAGON_LAIR), msg.sender, balance);
            emit Withdrawn(rewardToken, msg.sender, balance);
            uint256 reward = staker.reward;
            if (reward > 0) {
                staker.reward = 0;
                TransferHelper.safeTransfer(rewardToken, msg.sender, reward);                
                emit RewardPaid(rewardToken, msg.sender, reward);
            }
        }        
    }

    function updateReward(address _rewardToken, address _account) internal {
        Staking storage staking = s.staking[_rewardToken];
        staking.rewardPerTokenStored = rewardPerToken(_rewardToken);
        staking.lastUpdateTime = lastTimeRewardApplicable(_rewardToken);
        if (_account != address(0)) {
            Staker storage staker = staking.stakers[_account];
            staker.reward = earned(_rewardToken, _account);
            staker.userRewardPerTokenPaid = staking.rewardPerTokenStored;
        }        
    }

    struct RewardInfo {
        address rewardToken;
        uint256 reward;
        uint256 rewardDuration;
    }


    function notifyRewardAmount(RewardInfo[] calldata _rewards) external onlyOwner {
        for(uint256 i; i < _rewards.length; i++) {
            RewardInfo calldata reward = _rewards[i];
            updateReward(reward.rewardToken, address(0));
            Staking storage staking = s.staking[reward.rewardToken];
            require(block.timestamp.add(reward.rewardDuration) >= staking.periodFinish, "Cannot reduce existing period");
            
            uint256 rewardRate;
            if (block.timestamp >= staking.periodFinish) {
                rewardRate = reward.reward.div(reward.rewardDuration);
            } else {
                uint256 remaining = staking.periodFinish.sub(block.timestamp);
                uint256 leftover = remaining.mul(staking.rewardRate);
                rewardRate = reward.reward.add(leftover).div(reward.rewardDuration);
            }
            staking.rewardRate = rewardRate;

            // Ensure the provided reward amount is not more than the balance in the contract.
            // This keeps the reward rate in the right range, preventing overflows due to
            // very high values of rewardRate in the earned and rewardsPerToken functions;
            // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
            uint balance = IERC20(reward.rewardToken).balanceOf(address(this));
            require(rewardRate <= balance.div(reward.rewardDuration), "Provided reward too high");

            staking.lastUpdateTime = block.timestamp;
            uint256 periodFinish = block.timestamp.add(reward.rewardDuration);
            staking.periodFinish = periodFinish;
            emit RewardAdded(reward.rewardToken, reward.reward, periodFinish);
        }
    }

    modifier onlyOwner {
        require(s.owner == msg.sender, "Not owner");
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        emit OwnershipTransferred(s.owner, _newOwner);
        s.owner = _newOwner;
    }

    function owner() external view returns (address owner_) {
        owner_ = s.owner;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RewardAdded(address indexed _rewardToken, uint256 _reward, uint256 _periodFinish);
    event Staked(address indexed _rewardToken, address indexed _staker, uint256 _amount);
    event Withdrawn(address indexed _rewardToken, address indexed _staker, uint256 _amount);
    event RewardPaid(address indexed _rewardToken, address indexed _staker, uint256 _reward);
    
  
}