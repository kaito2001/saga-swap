// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
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
        require(balanceOf[msg.sender] >= amount, "ERC20: insufficient balance");
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
        require(balanceOf[sender] >= amount, "ERC20: insufficient balance");
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
        
        // Create trading pairs
        pairAB = factory.createPair(address(tokenA), address(tokenB));
        pairAC = factory.createPair(address(tokenA), address(tokenC));
        
        // Mint tokens for user
        tokenA.transfer(user, 500 ether);
        tokenB.transfer(user, 500 ether);
        tokenC.transfer(user, 500 ether);

    }

    function testAddLiquidityAB() public {
        // User calls addLiquidity
        vm.startPrank(user);

        uint balanceA = tokenA.balanceOf(user);
        uint balanceB = tokenB.balanceOf(user);
        console.log("User Balance of Token A: %s", balanceA);
        console.log("User Balance of Token B: %s", balanceB);
        assertEq(balanceA, 500 ether, "User's balance of Token A is not as expected");
        assertEq(balanceB, 500 ether, "User's balance of Token B is not as expected");

        // Ensure the user has approved enough tokens for the router
        tokenA.approve(address(router), 1000 ether);
        tokenB.approve(address(router), 1000 ether);

        // Now call addLiquidity
        router.addLiquidity(address(tokenA), address(tokenB), 1 ether, 1 ether);
        
        // Check LP token balance after adding liquidity
        uint pairBalance = IERC20(pairAB).balanceOf(user);
        assertEq(pairBalance, 200 ether, "LP token balance after adding liquidity is not as expected");

        vm.stopPrank();
    }

    // function testAddLiquidityAC() public {
    //     // User calls addLiquidity
    //     vm.startPrank(user);
    //     router.addLiquidity(address(tokenA), address(tokenC), 150 ether, 150 ether);
    //     uint pairBalance = IERC20(pairAC).balanceOf(user);
    //     console.log("Pair AC Balance: %s", pairBalance);
    //     assertEq(pairBalance, 300 ether); // Check LP token balance after adding liquidity
    //     vm.stopPrank();
    // }

    // function testSwapAB() public {
    //     router.addLiquidity(address(tokenA), address(tokenB), 100 ether, 100 ether);
    //     uint balanceBefore = tokenB.balanceOf(user);
    //     console.log("Balance Before Swap (B): %s", balanceBefore);
        
    //     router.swap(address(tokenA), address(tokenB), 10 ether, 9 ether, user);
        
    //     uint balanceAfter = tokenB.balanceOf(user);
    //     console.log("Balance After Swap (B): %s", balanceAfter);
        
    //     // Check the change in tokenB balance after swap
    //     assertEq(balanceAfter - balanceBefore, 9 ether); 
    // }

    // function testSwapAC() public {
    //     router.addLiquidity(address(tokenA), address(tokenC), 150 ether, 150 ether);
    //     uint balanceBefore = tokenC.balanceOf(user);
    //     console.log("Balance Before Swap (C): %s", balanceBefore);

    //     router.swap(address(tokenA), address(tokenC), 20 ether, 18 ether, user);
        
    //     uint balanceAfter = tokenC.balanceOf(user);
    //     console.log("Balance After Swap (C): %s", balanceAfter);
        
    //     // Check the change in tokenC balance after swap
    //     assertEq(balanceAfter - balanceBefore, 18 ether); 
    // }
}
