// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Factory.sol";

contract Router {
    Factory public factory;

    constructor(address _factory) {
        factory = Factory(_factory);
    }

  function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountA,
        uint amountB
    ) external {
        // Check if the pair already exists
        address pair = factory.getPair(tokenA, tokenB);
        if (pair == address(0)) {
            // Create a new pair if it does not exist
            pair = factory.createPair(tokenA, tokenB);
        }

        // Transfer tokens to the pair
        require(IERC20(tokenA).transferFrom(msg.sender, pair, amountA), "Transfer of tokenA failed");
        require(IERC20(tokenB).transferFrom(msg.sender, pair, amountB), "Transfer of tokenB failed");

        // Call mint to create LP tokens for the liquidity provider
        Pair(pair).mint(msg.sender);
    }

    function swap(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        address to
    ) external {
        address pair = factory.getPair(tokenIn, tokenOut);
        require(pair != address(0), "Router: PAIR_DOES_NOT_EXIST");
        IERC20(tokenIn).transferFrom(msg.sender, pair, amountIn);
        Pair(pair).swap(amountIn, amountOutMin, to);
    }
}
