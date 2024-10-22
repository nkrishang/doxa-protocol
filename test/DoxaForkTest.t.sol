// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {DoxaBondingCurve} from "src/DoxaBondingCurve.sol";
import {DoxaFactory} from "src/DoxaFactory.sol";
import {FixedPointMathLib} from "lib/solady/src/utils/FixedPointMathLib.sol";

import {IUniswapV2Pair} from "src/interface/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "src/interface/IUniswapV2Factory.sol";
import {IUniswapV2Router01} from "src/interface/IUniswapV2Router01.sol";

contract DoxaForkTest is Test {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CONSTANTS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    uint256 private constant DECAY_RATE = 0.997 ether;
    uint256 private constant A = 10_000 ether;
    uint256 private constant MAX_VALUE = 10 ether;
    uint256 private constant LP_AMOUNT_PER_ETHER = 7404842595397826248704;
    address private constant WETH = 0x4200000000000000000000000000000000000006;
    address private constant UNISWAP_V2_FACTORY = 0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6;
    address private constant UNISWAP_V2_ROUTER = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       EVENTS                               */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event BuyTokens(address indexed buyer, uint256 tokenAmount, uint256 etherAmount);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ERRORS                               */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error ZeroValueSent();
    error OverMaxValueSent();
    error BuybackDisabled();
    error ZeroEtherBalance();


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       TEST VARS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    DoxaFactory public factory;
    DoxaBondingCurve public bondingCurve;
    IUniswapV2Factory public uniswapV2Factory;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       SETUP                                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function setUp() public {
        uniswapV2Factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);

        factory = new DoxaFactory();
        bondingCurve = DoxaBondingCurve(factory.createToken("MyToken", "TKN", "ipfs://", bytes32("Salt")));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       TEST: DEPLOY                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function test_deploymentAddress() public {
        address addr = factory.createToken("MyToken", "TKN", "ipfs://", bytes32("Some Salt"));
        assertEq(addr, factory.predictTokenAddress(bytes32("Some Salt")));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       TEST: BUY                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function test_buy_revert_zeroValueSent() public {
        vm.expectRevert(ZeroValueSent.selector);
        bondingCurve.buy();
    }

    function test_buy_revert_overMaxValueSent() public {
        vm.expectRevert(OverMaxValueSent.selector);
        bondingCurve.buy{value: MAX_VALUE + 1}();
    }

    function test_fuzz_buy_amounts(uint256 x, uint256 y) public {
        vm.assume(x > 0 && x <= MAX_VALUE);
        vm.assume(y > 0 && y <= MAX_VALUE);
        
        // Bob is the first purchaser, and he buys tokens worth `x` ether at the initial price.
        address bob = address(0x123);
        vm.deal(bob, x);

        // Purchase tokens
        vm.prank(bob);
        uint256 amountOutX = bondingCurve.buy{value: x}();

        // Simulates the purchase and state updates.
        (uint256 amountOutCheckX, uint256 newActiveTierX, uint256 unfulfilledInNewTierX) = _simulateBuyTransaction({etherAmount: x, startTier: 0, unfulfilledAmountInTier: 1 ether});

        assertEq(bondingCurve.balanceOf(bob), amountOutX);
        // The two methods of calculating amountOut (in contract vs. in `_simulateBuyTransaction`) differ in decimal precision for high amounts.
        if(amountOutX > 1 ether) {
            (amountOutX, amountOutCheckX) = amountOutX > amountOutCheckX ? (amountOutX, amountOutCheckX) : (amountOutCheckX, amountOutX);
            assertTrue((amountOutX - amountOutCheckX) < 1e8);    
        } else {
            assertEq(amountOutX, amountOutCheckX);
        }
        assertEq(unfulfilledInNewTierX, bondingCurve.unfulfilledEtherInTier());
        assertEq(newActiveTierX, bondingCurve.tier());


        // Alice is the next purchaser, and she buys tokens worth `y` ether at the updated price.
        address alice = address(0x456);
        vm.deal(alice, y);

        // Purchase tokens
        vm.prank(alice);
        uint256 amountOutY = bondingCurve.buy{value: y}();

        // Simulates the purchase and state updates.
        (uint256 amountOutCheckY, uint256 newActiveTierY, uint256 unfulfilledInNewTierY) = _simulateBuyTransaction(y, newActiveTierX, unfulfilledInNewTierX);

        assertEq(bondingCurve.balanceOf(alice), amountOutY);
        if(amountOutY > 1 ether) {
            // The two methods of calculating amountOut (in contract vs. in `_simulateBuyTransaction`) differ in decimal precision for high amounts.
            (amountOutY, amountOutCheckY) = amountOutY > amountOutCheckY ? (amountOutY, amountOutCheckY) : (amountOutCheckY, amountOutY);
            assertTrue((amountOutY - amountOutCheckY) < 1e8);
        } else {
            assertEq(amountOutY, amountOutCheckY);
        }
        assertEq(unfulfilledInNewTierY, bondingCurve.unfulfilledEtherInTier());
        assertEq(newActiveTierY, bondingCurve.tier());
    }

    function test_fuzz_buy_lp(uint256 y) public {
        uint256 x = 7.3 ether;
        vm.assume(y > 1 ether && y <= MAX_VALUE);

        // Bob is the first purchaser, and he buys tokens worth `x` ether at the initial price.
        address bob = address(0x123);
        vm.deal(bob, x);

        // Purchase tokens
        vm.prank(bob);
        bondingCurve.buy{value: x}();

        // Check pool reserves
        IUniswapV2Pair uniswapV2Pair = IUniswapV2Pair(uniswapV2Factory.getPair(WETH, address(bondingCurve)));

        (uint256 reserve0X, uint256 reserve1X, ) = uniswapV2Pair.getReserves();
        
        uint256 result = FixedPointMathLib.mulWad(LP_AMOUNT_PER_ETHER, x);
        assertEq(reserve0X, x);
        if(result > reserve1X) {
            assertTrue(result - reserve1X < 10);
        } else {
            assertTrue(reserve1X - result < 10);
        }

        // Check whether LP shares minted to the contract
        uint256 bal = uniswapV2Pair.balanceOf(address(bondingCurve));
        assertGt(bal, 0);

        // Alice is the next purchaser, and she buys tokens worth `y` ether at the updated price.
        address alice = address(0x456);
        vm.deal(alice, y);

        // Purchase tokens
        vm.prank(alice);
        bondingCurve.buy{value: y}();

        // Check pool reserves
        (uint256 reserve0XY, uint256 reserve1XY, ) = uniswapV2Pair.getReserves();

        result = FixedPointMathLib.mulWad(LP_AMOUNT_PER_ETHER, (x+y));
        assertEq(reserve0XY, x+y);    
        if(result > reserve1XY) {
            assertTrue(result - reserve1XY < 10);
        } else {
            assertTrue(reserve1XY - result < 10);
        }

        assertGt(uniswapV2Pair.balanceOf(address(bondingCurve)), bal);

        // Check token price.
        assertEq(FixedPointMathLib.divWadUp(reserve1XY, reserve0XY), LP_AMOUNT_PER_ETHER);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       TEST: BUYBACK                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function test_buyback_revert_zeroBalance() public {

        for(uint256 i = 0; i < 100; i++) {
            bondingCurve.buy{value: 1 ether}();
        }

        vm.expectRevert(ZeroEtherBalance.selector);
        bondingCurve.buyback();
    }

    function test_buyback_revert_disabled() public {
        vm.expectRevert(BuybackDisabled.selector);
        bondingCurve.buyback();
    }

    function test_fuzz_buyBack(uint256 x) public {
        vm.assume(x > 1 ether && x <= MAX_VALUE);
        uint256 total;

        while(true) {
            bondingCurve.buy{value: x}();
            total += x;

            if(total >= 100 ether) {
                break;
            }
        }
        assertEq(address(bondingCurve).balance, 0);

        total = 0;
        for(uint256 i = 0; i < 1000; i++) {
            bondingCurve.buy{value: x}();
            total += x;
        }
        
        uint256 totalSupply = bondingCurve.totalSupply();

        uint256 contractBalance = address(bondingCurve).balance;
        assertEq(contractBalance, total);

        uint256 amountOutSimulated = _simulateBuyback(contractBalance);
        bondingCurve.buyback();
        
        assertEq(bondingCurve.totalSupply(), totalSupply - amountOutSimulated);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       HELPERS                              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _simulateBuyTransaction(uint256 etherAmount, uint256 startTier, uint256 unfulfilledAmountInTier) internal pure returns (uint256 amountOut, uint256 newActiveTier, uint256 unfulfilledInNewTier) {
        assert(unfulfilledAmountInTier > 0);
        assert(unfulfilledAmountInTier <= 1 ether);

        uint256 n = startTier;
        uint256 value = etherAmount;
        
        if(unfulfilledAmountInTier < 1 ether) {
            if (value < unfulfilledAmountInTier) {
                amountOut = FixedPointMathLib.mulWad(value, FixedPointMathLib.mulWad(A, uint256(FixedPointMathLib.powWad(int(DECAY_RATE), int(n)))));
                unfulfilledInNewTier = unfulfilledAmountInTier - value;
                newActiveTier = n;

                return (amountOut, newActiveTier, unfulfilledInNewTier);
            }

            amountOut += FixedPointMathLib.mulWad(unfulfilledAmountInTier, FixedPointMathLib.mulWad(A, uint256(FixedPointMathLib.powWad(int(DECAY_RATE), int(n)))));
            value -= unfulfilledAmountInTier;
            n += 1 ether;
        }

        while(value > 0) {            
            uint256 decay = uint256(FixedPointMathLib.powWad(int(DECAY_RATE), int(n)));        
            if (value < 1 ether) {
                amountOut += FixedPointMathLib.mulWad(value, FixedPointMathLib.mulWad(A, decay));
                unfulfilledInNewTier = 1 ether - value;
                newActiveTier = n;

                value = 0;
            } else {
                amountOut += FixedPointMathLib.mulWad(A, decay);
                value -= 1 ether;
                n += 1 ether;   
            }
        }
        newActiveTier = n;
        unfulfilledInNewTier = unfulfilledInNewTier == 0 ? 1 ether : unfulfilledInNewTier;

        return (amountOut, newActiveTier, unfulfilledInNewTier);
    }

    function _simulateBuyback(uint256 etherAmount) internal view returns (uint256 amountBurned) {
        IUniswapV2Pair uniswapV2Pair = IUniswapV2Pair(uniswapV2Factory.getPair(WETH, address(bondingCurve)));
        (uint256 reserveX, uint256 reserveY, ) = uniswapV2Pair.getReserves();

        amountBurned = IUniswapV2Router01(UNISWAP_V2_ROUTER).getAmountOut(etherAmount, reserveX, reserveY);
    }
}
