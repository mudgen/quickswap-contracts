## `QuickswapSyrupPools.sol`

This contract replaces the `StakingRewards.sol` contract for Quickswap Syrup Pools. It uses the same logic for staking but provides many possible user-interface improvements by enabling multiple actions to occur in a single transaction.

### Architecture Change

With `StakingRewards.sol` a separate contract is deployed for each Syrup Pool. This is changed with the new `QuickswapSyrupPools.sol` contract. With `QuickswapSyrupPools.sol` a single contract is deployed that contains any number of Syrup Pools.  Note that this is different than the [megapool](https://github.com/QuickSwap/megapool) contract which provides a single pool with many possible reward tokens.

After `QuickswapSyrupPools.sol` is deployed any number of Syrup Pools can be added to it.  Each Syrup Pool is associated with one reward token. People stake dQUICK into a Syrup Pool and earn reward tokens from one ERC20 contract.

This change of architecture enables easier on-chain management and tracking of all Syrup Pools and enables an action to occur on multiple Syrup Pools in a single transaction. For example it enables a person to stake their dQUICK into multiple Syrup Pools in a single transaction.

### New Functionality

The `QuickswapSyrupPools.sol` contract offers various new functionality that can see in the descriptions of functions below.

New staking and unstaking functionality:

1. A user can stake dQUICK into multiple Syrup Pools in a single transaction.
2. A user can convert QUICK to dQUICK and stake it into multiple Syrup Pools in a single transaction.
3. A user can withdraw specific amounts of dQUICK from multiple Syrup Pools in a single transaction.
4. A user can withdraw specific amounts dQUICK from multiple Syrup Pools and convert it to QUICK in a single transaction.
5. A user can withdraw all her dQUICK from all Syrup Pools she has staked in, in a single transaction.
6. A user can withdraw all her dQUICK from all Syrup Pools she has staked in, and automatically convert it into QUICK in a single transaction.
7. A user can claim rewards (getRewards) from multiple Syrup Pools in a single transaction.
8. A user can claim rewards (getRewards) from all Syrup Pools she has rewards in,  in a single transaction.
9. A user can withdraw specific amounts of dQUICK from multiple Syrup Pools and claim rewards from those Syrup Pools in a single transaction.
10. A user can withdraw specific amounts dQUICK from multiple Syrup Pools and convert it to QUICK and claim rewards from those Syrup Pools in a single transaction.
11. A user can withdraw all her dQUICK from all Syrup Pools she has staked in and claim rewards from those Syrup Pools, in a single transaction.
12. A user can withdraw all her dQUICK from all Syrup Pools she has staked in and claim rewards from those Syrup Pools , and automatically convert the dQUICK into QUICK in a single transaction.

New read-only, on-chain functionality:
1. The `totalSupply()` function returns the total staked dQUICK across all Syrup Pools.
2. The `totalSupply(address _rewardToken)` function returns the total dQUICK staked in a specific Syrup Pool.
3. The `balanceOf(address _rewardToken, address _account)` function returns the total dQUICK staked in a specific Syrup Pool by a specific staker.
4. The `balanceOf(address _account)` function returns the total dQUICK staked in all Syrup Pools by a specific staker.
5. The `pool(address _rewardToken)` function returns information about a specific Syrup Pool.
6. The `pools()` function returns information about all Syrup Pools.
7. The `stakerPool(address _rewardToken, address _staker)` function returns staker information about a specific Syrup Pool and specific staker, including how much dQUICK the staker staked and how many reward tokens are available for claiming.
8. The `stakerPools(address _staker)` function returns staker information about all Syrup Pools that the staker has dQUICK staked in or has rewards available in.

Adding new Syrup Pools

1. The `notifyRewardAmount(RewardInfo[] calldata _rewards) external onlyOwner` function enables the owner of the contract to add new Syrup Pools.

### Staking
#### stake function

```Solidity
//SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

struct StakeInput {
    address rewardToken;
    uint256 amount;        
}
 
function stake(StakeInput[] calldata _stakes) external;
```

The `stake` function enables people to stake dQUICK into one or more Syrup Pools in a single transaction.

This function requires that a user approves the `QuickswapSyrupPools` contract to transfer dQUICK on their behalf.

---
#### enterDragonLairAndStake function

```Solidity
//SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

struct QuickStakeInput {
    address rewardToken;
    uint256 quickAmount;
}
    
function enterDragonLairAndStake(QuickStakeInput[] calldata _quickStakeInput)
```

The `enterDragonLairAndStake` function enables users to stake QUICK into Syrup Pools.  It automatically converts QUICK into dQUICK and stakes it. This function saves the user the trouble of having to first convert their QUICK to dQUICK before staking.

This function requires that a user approves the `QuickswapSyrupPools` contract to transfer QUICK on their behalf. Note that it does not require the user to approve `QuickswapSyrupPools` for transferring dQUICK.

---
### Withdrawing

Note that withdrawing returns dQUICK back to its owner but does not claim any rewards.
#### withdraw(StakeInput[] calldata _stakes)

```Solidity
//SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

struct StakeInput {
    address rewardToken;
    uint256 amount;        
}

function withdraw(StakeInput[] calldata _stakes) external;
```

The `withdraw(StakeInput[] calldata _stakes)` function enables a user to remove a specified amount of dQUICK from one or more Syrup Pools in a single transaction.

---
#### withdrawAndDragonLair(StakeInput[] calldata _stakes)

```Solidity
//SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

struct StakeInput {
    address rewardToken;
    uint256 amount;        
}

function withdrawAndDragonLair(StakeInput[] calldata _stakes) external;
```

The `withdrawAndDragonLair(StakeInput[] calldata _stakes)` function enables a user to remove a specified amount of dQUICK from one or more Syrup Pools and automatically converts it to QUICK and transfers it to the user, all in a single transaction.

---
#### withdrawAll(address[] calldata _rewardTokens)

The `withdrawAll(address[] calldata _rewardTokens)` function enables a user to remove all their staked dQUICK from one or more Syrup Pools.

---

#### withdrawAllAndDragonLair(address[] calldata _rewardTokens)

The `withdrawAllAndDragonLair(address[] calldata _rewardTokens)` function enables a user to remove all their dQUICK from one or more Syrup Pools and automatically converts it to QUICK and transfers it to the user, all in a single transaction.

---
#### withdrawAllFromAll()

The `withdrawAllFromAll()` function enables a user to remove all their staked dQUICK from all Syrup Pools in a single transaction.

---
### Claiming Rewards
#### getRewards(address[] calldata _rewardTokens)

The `getRewards(address[] calldata _rewardTokens)` function enables a user to claim reward tokens from one or more Syrup Pools in a single transaction. 

---
#### getAllRewards()

The `getAllRewards()` function enables a user to claim reward tokens from all the Syrup Pools the user has rewards in, in a single transaction.

---
### Exit functions
Note: These functions enable a user to remove staked dQUICK and claim reward tokens from one or more Syrup Pools in a single transaction.

#### exit(StakeInput[] calldata _stakes)

```Solidity
//SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

struct StakeInput {
    address rewardToken;
    uint256 amount;        
}

function exit(StakeInput[] calldata _stakes) external;
```

The `exit(StakeInput[] calldata _stakes)` function enables a user to unstake a specified amount of dQUICK for each specified Syrup Pool and claim reward tokens from those Syrup Pools.

---

#### exitAndDragonLair(StakeInput[] calldata _stakes)

```Solidity
//SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

struct StakeInput {
    address rewardToken;
    uint256 amount;        
}

function exitAndDragonLair(StakeInput[] calldata _stakes);
```

The `exit(StakeInput[] calldata _stakes)` function enables a user to unstake a specified amount of dQUICK for each specified Syrup Pool and claim reward tokens from those Syrup Pools. The unstaked dQUICK is automatically converted to QUICK and transferred to the user. This is all done in a single transaction.

---

#### exitAll(address[] calldata _rewardTokens)

The `exitAll(address[] calldata _rewardTokens)` function enables a user to unstake all his staked dQUICK for each specified Syrup Pool and claim reward tokens from those Syrup Pools. 

---

#### exitAllAndDragonLair(address[] calldata _rewardTokens)

The `exitAllAndDragonLair(address[] calldata _rewardTokens)` function enables a user to unstake all his staked dQUICK for each specified Syrup Pool and claim reward tokens from those Syrup Pools. The unstaked dQUICK is automatically converted to QUICK and transferred to the user. This is all done in a single transaction.

---

#### exitAllFromAll()

The `exitAllFromAll()` function enables a user to unstake all her staked dQUICK for all Syrup Pools she has dQUICK staked in and claim reward tokens from those Syrup Pools. 

---

#### exitAllFromAllAndDragonLair()

The `exitAllFromAllAndDragonLair()` function enables a user to unstake all her staked dQUICK for all Syrup Pools she has dQUICK staked in and claim reward tokens from those Syrup Pools. The unstaked dQUICK is automatically converted to QUICK and transferred to the user. This is all done in a single transaction.

---

### Adding Syrup Pools

#### notifyRewardAmount(RewardInfo[] calldata _rewards) external onlyOwner
```Solidity
//SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

struct RewardInfo {
    address rewardToken;
    uint256 reward;
    uint256 rewardDuration;
}

function notifyRewardAmount(RewardInfo[] calldata _rewards) external onlyOwner {
```

The `notifyRewardAmount(RewardInfo[] calldata _rewards)` function is used to add Syrup Pools or extend or restart Syrup Pools.

### Removing Syrup Pools

#### removeStakingPools(address[] calldata _rewardTokens) external onlyOwner

This function is used to remove Syrup Pools from the internal array of Syrup Pools.

Removing Syrup Pools affects the return results of these functions:
* totalSupply()
* pools()

dQUICK cannot be staked into a Syrup Pool that has been removed.

Note that stakers can still withdraw, exit and claim from Syrup Pools that have been removed.



















