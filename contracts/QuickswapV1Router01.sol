pragma solidity =0.6.6;

import "./UniswapV2Router02.sol";
import "./interfaces/IERC20.sol";

interface IStakingReward {
    function stake(uint256 amount, address staker) external;
}

// constructor(address _factory, address _WETH)
contract QuickswapV1Router01 is UniswapV2Router02(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32, 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270) {
     function addLiquidityAndStake(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        address rewardPool
    ) external ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(address(this));
        if(IUniswapV2Pair(pair).allowance(msg.sender, rewardPool) < liquidity) {
            IUniswapV2Pair(pair).approve(rewardPool, type(uint256).max);
        }
        IStakingReward(rewardPool).stake(liquidity, msg.sender);
    }

    



}