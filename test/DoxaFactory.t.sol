// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {DoxaFactory} from "src/DoxaFactory.sol";

contract DoxaFactoryTest is Test {
    DoxaFactory public factory;

    function setUp() public {
        factory = new DoxaFactory();
    }
}
