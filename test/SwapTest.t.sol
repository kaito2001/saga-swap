// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// The import for Test.sol is commented out due to a parser error.
// import {Test, console} from "forge-std/Test.sol";
import {Test} from "forge-std/Test.sol"; // Adjusted import to avoid parser error
import "../src/Factory.sol";
import "../src/Router.sol";
import "../src/Pair.sol";

contract ERC20Mock is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    constructor(string memory _name, string memory _symbol, uint _supply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _supply;
        balanceOf[msg.sender] = _supply;
    }

    function transfer(address recipient, uint amount) external override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        require(allowance[sender][msg.sender] >= amount, "ERC20: insufficient allowance");
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        allowance[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}

contract SwapTest is Test {
    Factory factory;
    Router router;
    ERC20Mock tokenA;
    ERC20Mock tokenB;
    ERC20Mock tokenC;
    address pairAB;
    address pairAC;
    address user = address(0x123);

    function setUp() public {
        factory = new Factory();
        router = new Router(address(factory));
        tokenA = new ERC20Mock("TokenA", "TKA", 1000 ether);
        tokenB = new ERC20Mock("TokenB", "TKB", 1000 ether);
        tokenC = new ERC20Mock("TokenC", "TKC", 1000 ether);
        
        tokenA.approve(address(router), type(uint).max);
        tokenB.approve(address(router), type(uint).max);
        tokenC.approve(address(router), type(uint).max);

        // Tạo cặp giao dịch
        pairAB = factory.createPair(address(tokenA), address(tokenB));
        pairAC = factory.createPair(address(tokenA), address(tokenC));
    }

    function testAddLiquidityAB() public {
        router.addLiquidity(address(tokenA), address(tokenB), 100 ether, 100 ether);
        assertEq(IERC20(pairAB).balanceOf(address(this)), 200 ether);
    }

    function testAddLiquidityAC() public {
        router.addLiquidity(address(tokenA), address(tokenC), 150 ether, 150 ether);
        assertEq(IERC20(pairAC).balanceOf(address(this)), 300 ether);
    }

    function testSwapAB() public {
        router.addLiquidity(address(tokenA), address(tokenB), 100 ether, 100 ether);
        uint balanceBefore = tokenB.balanceOf(user);
        router.swap(address(tokenA), address(tokenB), 10 ether, 9 ether, user);
        uint balanceAfter = tokenB.balanceOf(user);
        assertEq(balanceAfter - balanceBefore, 9 ether);
    }

    function testSwapAC() public {
        router.addLiquidity(address(tokenA), address(tokenC), 150 ether, 150 ether);
        uint balanceBefore = tokenC.balanceOf(user);
        router.swap(address(tokenA), address(tokenC), 20 ether, 18 ether, user);
        uint balanceAfter = tokenC.balanceOf(user);
        assertEq(balanceAfter - balanceBefore, 18 ether);
    }
}
