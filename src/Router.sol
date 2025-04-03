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
        address pair = factory.getPair(tokenA, tokenB);
        require(pair != address(0), "Router: PAIR_DOES_NOT_EXIST");
        IERC20(tokenA).transferFrom(msg.sender, pair, amountA);
        IERC20(tokenB).transferFrom(msg.sender, pair, amountB);
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
