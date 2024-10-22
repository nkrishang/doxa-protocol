// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {DoxaBondingCurve} from "src/DoxaBondingCurve.sol";
import {DoxaFactory} from "src/DoxaFactory.sol";

contract DoxaBenchmarkTest is Test {

    DoxaFactory public factory;
    DoxaBondingCurve public bondingCurve;

    function setUp() public {
        factory = new DoxaFactory();
        bondingCurve = DoxaBondingCurve(factory.createToken("MyToken", "TKN", "ipfs://", bytes32("Salt")));
    }

    function test_benchmark_createToken() public {
        vm.pauseGasMetering();
        DoxaFactory fac = factory;
        vm.resumeGasMetering();
        fac.createToken("MyToken", "TKN", "ipfs://", bytes32("Some Salt"));
    }

    function test_benchmark_buy_oneEther() public {
        vm.pauseGasMetering();
        DoxaBondingCurve bc = bondingCurve;
        vm.resumeGasMetering();
        bc.buy{value: 1 ether}();
    }

    function test_benchmark_buy_lessThanOneEther() public {
        vm.pauseGasMetering();
        DoxaBondingCurve bc = bondingCurve;
        vm.resumeGasMetering();
        bc.buy{value: 0.5 ether}();
    }

    function test_benchmark_buy_betweenOneAndTwoEther() public {
        vm.pauseGasMetering();
        DoxaBondingCurve bc = bondingCurve;
        vm.resumeGasMetering();
        bc.buy{value: 1.5 ether}();
    }

    function test_benchmark_buy_maxEther() public {
        vm.pauseGasMetering();
        DoxaBondingCurve bc = bondingCurve;
        vm.resumeGasMetering();
        bc.buy{value: 10 ether}();
    }

    function test_benchmark_buyback() public {
        vm.pauseGasMetering();
        DoxaBondingCurve bc = bondingCurve;

        for(uint i = 0; i < 101; i++) {
            bc.buy{value: 1 ether}();
        }
        vm.resumeGasMetering();
        bc.buyback();
    }
}