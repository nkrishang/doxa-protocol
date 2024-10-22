// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {DoxaBondingCurveNoLp} from "test/utils/DoxaBondingCurveNoLp.sol";

contract DoxaInvariantTest is Test {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CONSTANTS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    uint256 private constant DECAY_RATE = 0.997 ether;
    uint256 private constant A = 10_000 ether;
    uint256 private constant MAX_VALUE = 10 ether;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       EVENTS                               */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event BuyTokens(address indexed buyer, uint256 tokenAmount, uint256 etherAmount);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ERRORS                               */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error ZeroValueSent();
    error OverMaxValueSent();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       TEST VARS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    DoxaBondingCurveNoLp public bondingCurve;

    uint256 public total;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       SETUP                                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function setUp() public {
        bondingCurve = new DoxaBondingCurveNoLp("MyToken", "TKN", "ipfs://");

        // Invariant tests:
        targetContract(address(this));

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = this.handler_buy.selector;

        targetSelector(FuzzSelector({ addr: address(this), selectors: selectors }));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       TESTS                                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function handler_buy(uint256 x) public {
        vm.assume(x > 0 && x <= MAX_VALUE);
        total += x;
        bondingCurve.buy{value: x}();
    }

    function invariant_unfulfilledEtherInTier() public view {
        uint256 unfulfilled = bondingCurve.unfulfilledEtherInTier();
        assertEq(unfulfilled, 1 ether - (total % 1 ether));
    }

    function invariant_tier() public view {
        uint256 n = bondingCurve.tier();
        assertEq(n, total - (total % 1 ether));
    }
}