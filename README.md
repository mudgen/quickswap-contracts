## `QuickswapSyrupPools.sol`

This contract replaces the `StakingRewards.sol` contract for Quickswap Syrup Pools. It uses the same logic for staking but provides many possible user-interface improvements by enabling multiple actions to occur in a single transaction.

### Architecture Change

With `StakingRewards.sol` a separate contract is deployed for each Syrup Pool. This is changed with new `QuickswapSyrupPools.sol` contract. With `QuickswapSyrupPools.sol` a single contract is deployed that contains any number of Syrup Pools.  Note that this is different than the [megapool](https://github.com/QuickSwap/megapool) contract which provides a single pool with many possible reward tokens.

After `QuickswapSyrupPools.sol` is deployed any number of Syrup Pools can be added to it.  Each Syrup Pool is assocaited with on reward token. People stake dQUICK into a Syrup pool and earn reward tokens from an ERC20 contract.

This change of architecture enables easier on-chain management of all Syrup Pools and enables an action to occur on multiple Syrup Pools in a single transaction. For example it enables a person to stake their dQUICK into multiple Syrup Pools in a single transaction.

## Staking
