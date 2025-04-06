// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Pair is ERC20 {
    address public token0;
    address public token1;
    uint112 private reserve0;
    uint112 private reserve1;

    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);

    constructor(string memory name_, string memory symbol_, address _token0, address _token1) ERC20(name_, symbol_) {
        token0 = _token0;
        token1 = _token1;
    }

    function _update(uint balance0, uint balance1) private {
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
    }

   function mint(address to) external returns (uint liquidity) {
    uint balance0 = IERC20(token0).balanceOf(address(this));
    uint balance1 = IERC20(token1).balanceOf(address(this));

    uint amount0 = balance0 - reserve0;
    uint amount1 = balance1 - reserve1;

    // Tính toán số lượng LP token sẽ mint dựa trên số lượng token đã thêm vào
    liquidity = sqrt(amount0 * amount1); // Ví dụ sử dụng công thức này cho việc mint LP token

    // Mint LP token cho người cung cấp thanh khoản
    _mint(to, liquidity); // Hàm _mint này sẽ thực hiện việc tạo LP token và cấp cho người cung cấp thanh khoản

    // Cập nhật số dư dự trữ
    _update(balance0, balance1);

    // Phát sự kiện Mint
    emit Mint(to, amount0, amount1);
}

    // Hàm tính căn bậc hai (sqrt) - đây chỉ là một ví dụ đơn giản để tính số lượng LP token cần mint
    function sqrt(uint x) internal pure returns (uint) {
        uint z = (x + 1) / 2;
        uint y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    function burn(address to) external returns (uint amount0, uint amount1) {
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        amount0 = balance0 - reserve0;
        amount1 = balance1 - reserve1;

        _update(balance0 - amount0, balance1 - amount1);

        emit Burn(msg.sender, amount0, amount1, to);
    }

   function swap(uint amount0Out, uint amount1Out, address to) external {
    require(amount0Out > 0 || amount1Out > 0, "Pair: INSUFFICIENT_OUTPUT_AMOUNT");
    require(to != token0 && to != token1, "Pair: INVALID_TO");

    uint _reserve0 = reserve0;
    uint _reserve1 = reserve1;

    require(amount0Out < _reserve0 && amount1Out < _reserve1, "Pair: INSUFFICIENT_LIQUIDITY");

    if (amount0Out > 0) IERC20(token0).transfer(to, amount0Out);
    if (amount1Out > 0) IERC20(token1).transfer(to, amount1Out);

    uint balance0 = IERC20(token0).balanceOf(address(this));
    uint balance1 = IERC20(token1).balanceOf(address(this));

    uint amount0In = balance0 > (_reserve0 - amount0Out) ? balance0 - (_reserve0 - amount0Out) : 0;
    uint amount1In = balance1 > (_reserve1 - amount1Out) ? balance1 - (_reserve1 - amount1Out) : 0;

    require(amount0In > 0 || amount1In > 0, "Pair: INSUFFICIENT_INPUT_AMOUNT");

    // Optional: apply fee, e.g. 0.3%
    // uint balance0Adjusted = balance0 * 1000 - amount0In * 3;
    // uint balance1Adjusted = balance1 * 1000 - amount1In * 3;
    // require(balance0Adjusted * balance1Adjusted >= uint(_reserve0) * uint(_reserve1) * (1000**2), "Pair: K");

    _update(balance0, balance1);

    emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
}

function getReserves() external view returns (uint, uint) {
    return (reserve0, reserve1);
}

function getPair() external view returns (address, address) {
    return (token0, token1);
}

}