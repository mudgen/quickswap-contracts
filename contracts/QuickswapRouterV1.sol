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
    uint32 periodFinish;
    uint32 lastUpdateTime;
    uint32 index; // index into rewardTokens array
    uint256 totalSupply;    
    uint256 rewardRate;    
    uint256 rewardPerTokenStored;    
    // staker => staker info    
    mapping(address => Staker) stakers;    
}


struct AppStorage {
    address owner;
    mapping(address => Staking) staking;
    address[] rewardTokens;
    // staker address => array of reward tokens
    mapping(address => address[]) stakerRewardTokens;
    // staker address => rewardToken => index in stakerRewardTokens array
    mapping(address => mapping(address => uint256)) stakerRewardTokenIndex;
}

// UniswapV2Router02 constructor args:  constructor(address _factory, address _WETH)
// is UniswapV2Router02(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32, 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270) 
contract QuickswapRouterV1 {
    AppStorage s;

    using SafeMath for uint256;    

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
                uint256(staking.rewardPerTokenStored).add(
                    lastTimeRewardApplicable(_rewardToken).sub(staking.lastUpdateTime).mul(staking.rewardRate).mul(1e18).div(staking.totalSupply)
                );
        }
    }

    function earned(address _rewardToken, address _account) public view returns (uint256) {
        Staking storage staking = s.staking[_rewardToken];
        Staker storage staker = staking.stakers[_account];
        return uint256(staker.balance).mul(rewardPerToken(_rewardToken).sub(staker.userRewardPerTokenPaid)).div(1e18).add(staker.reward);        
    }

    struct StakePool {
        address rewardToken;
        uint256 periodFinish;
        uint256 totalSupply;
        uint256 rewardRate;
        uint256 rewardPerToken;
    }

    function pool(address _rewardToken) public view returns (StakePool memory stakePool_) {
        Staking storage staking = s.staking[_rewardToken];
        stakePool_ = StakePool({
            rewardToken: _rewardToken,
            periodFinish: staking.periodFinish,
            totalSupply: staking.totalSupply,
            rewardRate: staking.rewardRate,
            rewardPerToken: rewardPerToken(_rewardToken)
        });
    }

    function pools() external view returns (StakePool[] memory stakePools_) {
        uint256 length = s.rewardTokens.length;
        stakePools_ = new StakePool[](length);
        for(uint256 i; i < length; i++) {
            address rewardToken = s.rewardTokens[i];
            stakePools_[i] = pool(rewardToken);
        }
    }

    struct StakerPool {
        address rewardToken;
        address staker;
        uint256 periodFinish;
        uint256 balance;
        uint256 earned;
    }

    function stakerPool(address _rewardToken, address _staker) public view returns (StakerPool memory stakerPool_) {
        Staking storage staking = s.staking[_rewardToken];
        Staker storage staker = staking.stakers[_staker];
        stakerPool_ = StakerPool({
            rewardToken: _rewardToken,
            staker: _staker,
            periodFinish: staking.periodFinish,
            balance: staker.balance,
            earned: earned(_rewardToken, _staker)
        });
    }

    function stakerPools(address _staker) external view returns (StakerPool[] memory stakerPools_) {
        uint256 length = s.stakerRewardTokens[_staker].length;
        stakerPools_ = new StakerPool[](length);
        for(uint256 i; i < length; i++) {
            stakerPools_[i] = stakerPool(s.stakerRewardTokens[_staker][i], _staker);
        }
    }
    
    struct StakeInput {
        address rewardToken;
        uint256 amount;        
    }
    
    function stake(StakeInput[] calldata _stakes) external {
        uint256 totalStaked;
        for(uint256 i; i < _stakes.length; i++) {
            StakeInput calldata stakeInput = _stakes[i];
            require(stakeInput.amount > 0, "Cannot stake 0");
            Staking storage staking = s.staking[stakeInput.rewardToken];
            if(staking.index == 0) {
                require(s.rewardTokens[0] == stakeInput.rewardToken, "rewardToken not authorized for staking");
            }
            updateReward(stakeInput.rewardToken, msg.sender);            
            staking.totalSupply = staking.totalSupply + stakeInput.amount;
            Staker storage staker = staking.stakers[msg.sender];
            uint256 balance = staker.balance;
            staker.balance = balance + stakeInput.amount;
            if(balance == 0 && staker.reward == 0) {                
                s.stakerRewardTokenIndex[msg.sender][stakeInput.rewardToken] = s.stakerRewardTokens[msg.sender].length;
                s.stakerRewardTokens[msg.sender].push(stakeInput.rewardToken);
            }
            totalStaked += stakeInput.amount;            
            emit Staked(stakeInput.rewardToken, msg.sender, stakeInput.amount);
        }
        TransferHelper.safeTransferFrom(address(DRAGON_LAIR), msg.sender, address(this), totalStaked);
    }   

    function withdraw(StakeInput[] calldata _stakes) external {
        uint256 totalWithdrawAmount;
        for(uint256 i; i < _stakes.length; i++) {
            _withdraw(_stakes[i].rewardToken, _stakes[i].amount);
            totalWithdrawAmount += _stakes[i].amount;
        }
        TransferHelper.safeTransfer(address(DRAGON_LAIR), msg.sender, totalWithdrawAmount);
    }

    function removeStakerStakingPools(address _rewardToken) internal {
        uint256 lastIndex =  s.stakerRewardTokens[msg.sender].length - 1;
        uint256 index = s.stakerRewardTokenIndex[msg.sender][_rewardToken];
        if(lastIndex != index) {
            address lastRewardToken = s.stakerRewardTokens[msg.sender][lastIndex];
            s.stakerRewardTokens[msg.sender][index] = lastRewardToken;
            s.stakerRewardTokenIndex[msg.sender][lastRewardToken] = index;
        }
        s.stakerRewardTokens[msg.sender].pop();
        delete s.stakerRewardTokenIndex[msg.sender][_rewardToken];
    }

    function removeStakingPools(address[] calldata _rewardTokens) external onlyOwner {
        for(uint256 i; i < _rewardTokens.length; i++) {
            address rewardToken = _rewardTokens[i];
            uint256 lastIndex = s.rewardTokens.length - 1;
            uint256 index = s.staking[rewardToken].index;
            if(index == 0) {
                require(s.rewardTokens[0] == rewardToken, "rewardToken not found");
            }
            if(lastIndex != index) {
                address lastRewardToken = s.rewardTokens[lastIndex];
                s.rewardTokens[index] = lastRewardToken;
                s.staking[lastRewardToken].index = uint32(index);
            }
            s.rewardTokens.pop();
            delete s.staking[rewardToken];
        }
    }

    function _withdraw(address _rewardToken, uint256 _amount) internal {        
        require(_amount > 0, "Cannot withdraw 0");        
        updateReward(_rewardToken, msg.sender);
        Staking storage staking = s.staking[_rewardToken];
        uint256 rewardTotalSupply = staking.totalSupply - _amount;
        staking.totalSupply = rewardTotalSupply;
        Staker storage staker = staking.stakers[msg.sender];
        uint256 balance = staker.balance - _amount;
        staker.balance = balance;
        if(balance == 0 && staker.reward == 0) {
            removeStakerStakingPools(_rewardToken);
        }
        emit Withdrawn(_rewardToken, msg.sender, _amount);        
    }

    function withdrawAll(address[] calldata _rewardTokens) public {
        uint256 totalWithdrawAmount;
        for(uint256 i; i < _rewardTokens.length; i++) {
            address rewardToken = _rewardTokens[i];
            uint256 balance = s.staking[rewardToken].stakers[msg.sender].balance;
            totalWithdrawAmount += balance;
            _withdraw(rewardToken, balance);            
        }
        TransferHelper.safeTransfer(address(DRAGON_LAIR), msg.sender, totalWithdrawAmount);
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
                if(staker.balance == 0) {
                    removeStakerStakingPools(rewardToken);
                }
            }
        }
        
    }

    function exit(address[] calldata _rewardTokens) external {       
        uint256 totalWithdrawAmount;             
        for(uint256 i; i < _rewardTokens.length; i++) {
            address rewardToken = _rewardTokens[i];
            updateReward(rewardToken, msg.sender);
            Staking storage staking = s.staking[rewardToken];
            Staker storage staker = staking.stakers[msg.sender];
            uint256 balance = staker.balance;
            totalWithdrawAmount += balance;
            removeStakerStakingPools(rewardToken);
            uint256 rewardTotalSupply = staking.totalSupply - balance;
            staking.totalSupply = rewardTotalSupply;
            staker.balance = 0;            
            emit Withdrawn(rewardToken, msg.sender, balance);
            uint256 reward = staker.reward;
            if (reward > 0) {
                staker.reward = 0;
                TransferHelper.safeTransfer(rewardToken, msg.sender, reward);                
                emit RewardPaid(rewardToken, msg.sender, reward);
            }            
        }
        TransferHelper.safeTransfer(address(DRAGON_LAIR), msg.sender, totalWithdrawAmount);
    }

    function updateReward(address _rewardToken, address _account) internal {
        Staking storage staking = s.staking[_rewardToken];
        staking.rewardPerTokenStored = rewardPerToken(_rewardToken);
        staking.lastUpdateTime = uint32(lastTimeRewardApplicable(_rewardToken));
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
            require(reward.rewardToken != address(0), "Reward token cannot be address(0)");
            addRewardToken(reward.rewardToken);
            updateReward(reward.rewardToken, address(0));
            Staking storage staking = s.staking[reward.rewardToken];
            require(block.timestamp.add(reward.rewardDuration) >= staking.periodFinish, "Cannot reduce existing period");
            
            uint256 rewardRate;
            if (block.timestamp >= staking.periodFinish) {
                rewardRate = reward.reward.div(reward.rewardDuration);
            } else {
                uint256 remaining = uint256(staking.periodFinish).sub(block.timestamp);
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

            staking.lastUpdateTime = uint32(block.timestamp);
            uint256 periodFinish = block.timestamp.add(reward.rewardDuration);
            staking.periodFinish = uint32(periodFinish);
            emit RewardAdded(reward.rewardToken, reward.reward, periodFinish);
        }
    }

    function addRewardToken(address _rewardToken) internal {
        uint256 index = s.staking[_rewardToken].index;
        if(index == 0 && s.rewardTokens[index] != _rewardToken) {
            s.staking[_rewardToken].index = uint32(s.rewardTokens.length);
            s.rewardTokens.push(_rewardToken);
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
