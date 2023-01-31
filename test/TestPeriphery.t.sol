// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "v2-periphery/interfaces/IUniswapV2Router02.sol";
import "v2-periphery/interfaces/IERC20.sol";

import "v2-core/interfaces/IUniswapV2Factory.sol";
import "v2-core/interfaces/IUniswapV2Pair.sol";

contract PeripheryTest is Test {
    IUniswapV2Factory public univ2factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Router02 public univ2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    // address public bnb = 0xB8c77482e45F1F44dE1745F52C74426C631bDD52;
    // address public stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public shibaInu = 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE;
    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address[] public coins;

    function setupFork() public {
        string memory MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
        uint256 forkId = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(forkId);
        vm.rollFork(14684371);
    }

    function dealCoins() public {
        coins.push(weth);
        coins.push(usdc);
        coins.push(usdt);
        // coins.push(bnb);
        // coins.push(stETH);
        coins.push(shibaInu);
        coins.push(dai);
        // coins
        for (uint256 i = 0; i < coins.length; i++) {
            deal({token: coins[i], to: address(this), give: 1 ether});
        }
    }

    function setUp() public {
        setupFork();
        dealCoins();
    }

    function testSwapExactETHForTokens() public {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = usdc;
        univ2Router.swapExactETHForTokens{value: 1 ether}(1000, path, address(this), ~uint128(0));
        console.log(IERC20(usdc).balanceOf(address(this)) / 1e6, "is my balance");
    }

    function testFailAddLiquidity() external {
        IERC20(usdc).approve(address(univ2Router), type(uint256).max);
        // console.log("Current allowance", IERC20(usdt).allowance(address(this), address(univ2factory)));
        IERC20(dai).approve(address(univ2Router), type(uint256).max);
        console.log("USDC BALANCE", IERC20(usdc).balanceOf(address(this)) / 1e6);
        console.log("DAI BALANCE", IERC20(dai).balanceOf(address(this)) / 1e18);

        univ2Router.addLiquidity(usdc, dai, 5e5, 5e5, 0, 0, address(this), ~uint128(0));
    }

    function testSuccessfulAddAndRemoveLiquidity() external {
        console.log("USDC balance is", IERC20(usdc).balanceOf(address(this)) / 1e6);
        console.log("DAI Balance is ", IERC20(dai).balanceOf(address(this)) / 1e18);
        IERC20(dai).approve(address(univ2Router), type(uint256).max);
        IERC20(usdc).approve(address(univ2Router), type(uint256).max);
        (uint256 amountA, uint256 amountB, uint256 liquidity) =
            univ2Router.addLiquidity(usdc, dai, 1e6, 1e18, 0, 0, address(this), ~uint128(0));
        console.log("Amount A", amountA, "Amount B", amountB);
        console.log("Total liquidity", liquidity);

        address pair = univ2factory.getPair(usdc, dai);
        console.log("USDC DAI PAIR ADDRESS", pair);
        IERC20(pair).approve(address(univ2Router), type(uint).max);
        // vm.warp(block.timestamp + 1_000_000_000);
        (uint256 amountA1, uint256 amountB1) =
        univ2Router.removeLiquidity(usdc, dai, liquidity, 0, 0, address(this), type(uint256).max);
        console.log("We got back ", amountA1, amountB1);
    }

    function testPairCreation() external {
        vm.expectRevert("UniswapV2: PAIR_EXISTS");
        univ2factory.createPair(weth, usdc);

        univ2factory.createPair(0x79B87d52a03ED26A19C1914be4CE37F812e2056c, usdc);
    }

    function testSwapExactForExact() external {
        address[] memory path = new address[](2);
        path[0] = usdc;
        path[1] = dai;
        IERC20(usdc).approve(address(univ2Router), type(uint256).max);
        uint256 daiBefore = IERC20(dai).balanceOf(address(this));
        uint256[] memory amounts =
            univ2Router.swapExactTokensForTokens(2e6, 1e18, path, address(this), type(uint256).max);
        uint256 daiAfter = IERC20(dai).balanceOf(address(this));

        console.log("Amounts are", amounts[0], amounts[1]);
        console.log("The change in DAI is", daiAfter - daiBefore);
    }

    function testSwapETHForExact() external {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

        console.log("Ether before", address(this).balance / 1e18);
        uint256[] memory amounts =
            univ2Router.swapETHForExactTokens{value: 10 ether}(1000e18, path, address(this), type(uint256).max);

        console.log("Amount 0 is ", amounts[0], amounts[1] / 1e18);
        console.log("Ether after", address(this).balance / 1e18);
        IERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984).approve(address(univ2Router), type(uint256).max);

        path[1] = weth;
        path[0] = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
        amounts = univ2Router.swapExactTokensForETH(1000e18, 1e18, path, address(this), type(uint256).max);

        console.log("amounts end", amounts[0] / 1e18, amounts[1] / 1e18);

        console.log("ETHER AFTER AFTER", address(this).balance);
    }


    function testCoreSwap() external {
        address USDC_DAI = 0xAE461cA67B15dc8dc81CE7615e0320dA1A9aB8D5;
        console.log(IUniswapV2Pair(USDC_DAI).token0());
        IERC20(usdc).transfer(USDC_DAI, 5e6);
        IUniswapV2Pair(USDC_DAI).swap(0, 4e6, address(this), bytes(""));
    } 

    fallback() external payable {}
}
