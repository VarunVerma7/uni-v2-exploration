// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "v2-periphery/interfaces/IUniswapV2Router02.sol";
import "v2-periphery/interfaces/IERC20.sol";

import "v2-core/interfaces/IUniswapV2Factory.sol";

contract CounterTest is Test {
    IUniswapV2Factory public univ2factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Router02  public univ2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function setupFork() public {
        string memory MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
        uint256 forkId = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(forkId);
        vm.rollFork(14684371);
    }

    function setUp() public {
        setupFork();
        vm.deal(address(this), 10 ether);
    }

    function testSwapExactETHForTokens() public {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = usdc;
        univ2Router.swapExactETHForTokens{value: 1 ether}(1000, path, address(this), ~uint128(0));
        console.log(IERC20(usdc).balanceOf(address(this)) / 1e6, "is my balance");
     
    }

    function testPairCreation() external {
        vm.expectRevert("UniswapV2: PAIR_EXISTS");
        univ2factory.createPair(weth, usdc);

        univ2factory.createPair(address(0x7), usdc);
    }

 
}
