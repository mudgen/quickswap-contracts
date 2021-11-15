## `QuickswapSyrupPools.sol`

This contract replaces the `StakingRewards.sol` contract for Quickswap Syrup Pools. It uses the same logic for staking but provides many possible user-interface improvements by enabling multiple actions to occur in a single transaction.

### Architecture Change

With `StakingRewards.sol` a separate contract is deployed for each Syrup Pool. This is changed with the new `QuickswapSyrupPools.sol` contract. With `QuickswapSyrupPools.sol` a single contract is deployed that contains any number of Syrup Pools.  Note that this is different than the [megapool](https://github.com/QuickSwap/megapool) contract which provides a single pool with many possible reward tokens.

After `QuickswapSyrupPools.sol` is deployed any number of Syrup Pools can be added to it.  Each Syrup Pool is associated with one reward token. People stake dQUICK into a Syrup pool and earn reward tokens from one ERC20 contract.

This change of architecture enables easier on-chain management and tracking of all Syrup Pools and enables an action to occur on multiple Syrup Pools in a single transaction. For example it enables a person to stake their dQUICK into multiple Syrup Pools in a single transaction.

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

Note that this is new functionality because it enables a user to specify the amount of dQUICK to remove from each Syrup Pool. The old `StakingRewards` contract only allowed a user to withdraw *all* dQUICK from a Syrup Pool and could only do so for one Syrup Pool per transaction.

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












