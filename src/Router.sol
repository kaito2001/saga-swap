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

    // Lấy reserves từ pair
    (uint reserve0, uint reserve1) = Pair(pair).getReserves();
    address token0 = Pair(pair).token0();
    address token1 = Pair(pair).token1();

    // Xác định reserveIn và reserveOut
    (uint reserveIn, uint reserveOut) = tokenIn == token0
        ? (reserve0, reserve1)
        : (reserve1, reserve0);

    // Tính amountOut dựa theo công thức AMM
    uint amountOut = getAmountOut(amountIn, reserveIn, reserveOut);
    require(amountOut >= amountOutMin, "Router: INSUFFICIENT_OUTPUT_AMOUNT");

    // Gửi tokenIn vào pool
    IERC20(tokenIn).transferFrom(msg.sender, pair, amountIn);

    // Tính amount0Out và amount1Out để truyền đúng vào Pair.swap
    (uint amount0Out, uint amount1Out) = tokenIn == token0
        ? (uint(0), amountOut)  // tokenIn là token0 -> swap từ token0 -> token1
        : (amountOut, uint(0)); // tokenIn là token1 -> swap từ token1 -> token0

    // Gọi swap ở Pair
    Pair(pair).swap(amount0Out, amount1Out, to);
}


function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to
) external {
    require(path.length >= 2, "Router: INVALID_PATH");

    // Transfer tokenIn từ user vào pool đầu tiên
    IERC20(path[0]).transferFrom(msg.sender, getPair(path[0], path[1]), amountIn);

    // Swap các bước
    for (uint i = 0; i < path.length - 1; i++) {
        address input = path[i];
        address output = path[i + 1];
        address pair = getPair(input, output);

        (uint reserveIn, uint reserveOut) = getReserves(input, output);

        // 🛠 Fix: Tính đúng amountInput
        uint amountInput = IERC20(input).balanceOf(pair) - reserveIn;
        uint amountOut = getAmountOut(amountInput, reserveIn, reserveOut);

        address nextPair = i < path.length - 2 ? getPair(output, path[i + 2]) : to;

        (uint amount0Out, uint amount1Out) = input < output
            ? (uint(0), amountOut)
            : (amountOut, uint(0));

        Pair(pair).swap(amount0Out, amount1Out, nextPair);
    }
}


function getPair(address tokenA, address tokenB) internal view returns (address) {
    return factory.getPair(tokenA, tokenB);
}

function getReserves(address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
    address pair = getPair(tokenA, tokenB);
    (uint reserve0, uint reserve1) = Pair(pair).getReserves();
    (reserveA, reserveB) = tokenA < tokenB ? (reserve0, reserve1) : (reserve1, reserve0);
}

function getAmountOut(
    uint amountIn,
    uint reserveIn,
    uint reserveOut
) internal pure returns (uint amountOut) {
    require(amountIn > 0, "Router: INSUFFICIENT_INPUT_AMOUNT");
    require(reserveIn > 0 && reserveOut > 0, "Router: INSUFFICIENT_LIQUIDITY");

    uint amountInWithFee = amountIn * 997;
    uint numerator = amountInWithFee * reserveOut;
    uint denominator = reserveIn * 1000 + amountInWithFee;
    amountOut = numerator / denominator;
}


}
