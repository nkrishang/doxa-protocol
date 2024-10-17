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
        bondingCurve = new DoxaBondingCurveNoLp("MyToken", "TKN");

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
        uint256 unfulfilled = bondingCurve.unfulfilledEtherTillNextTier();
        assertEq(unfulfilled, 1 ether - (total % 1 ether));
    }

    function invariant_tier() public view {
        uint256 n = bondingCurve.n_tier();
        assertEq(n, total - (total % 1 ether));
    }

//     function test_specific() public {

//         uint256 y;
//         uint256 amt;
        
//         y = 2891347155755;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 137;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 33199395;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 210;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 479;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 2;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 1;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 28913803559760000;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 4613;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 997000000000000000;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 19430000;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 3;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 2957397981;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 1766;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 3170000;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 3211736;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 1317;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 4163653872;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 9053245411;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 11244;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 5048;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 30;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 28626266;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 11937580405141182;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 14456323;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 121953207738874;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 3630;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 25979801856;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 92;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 658927908360;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 234;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 799404249395742;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 6610004;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 95795065564217076;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 1460;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 261194;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 1637055115;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 91685156439;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 2587;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 133435818874667250;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 15179;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 2;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 1849;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 1659860;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 1;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 185839115262;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 27854045253403;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 510;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 157;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 19202219;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 2097537592;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 27906;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 671973852627494870;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 1380881925064406;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 1561;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 737062167441790035;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 166224734200903222;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 40744015;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 26026605148018;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 19260000;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 4058;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 1741;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 30891;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 13990118434759;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 1765;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 3954581269;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 1;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 4247675890690783;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 343356212307;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 3731420;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 2369;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 33199394;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 29542878107903920;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 962023755203784726;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 3170000;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 35127986409344;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 48479600;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 4072;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 1693;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 2;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 207674;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 87;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 37124682;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 1;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 7846377;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 680658719;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 27;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 345;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 532113753339411831;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 4081;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 3857;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 1287;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 2;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 8210144230706732945;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 3;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 3821400007878059;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 21636599;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 5767;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 60294702826;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 48938314;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 483;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 18190343400248;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 159433208708843134;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 4494984;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 6175;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 155282993297014036;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 23459765679;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 3966227;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 23678217;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 305980836557647035;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 2891347155755;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 488192160216796;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 408757808150;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 3821400007878058;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 1;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 3;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 4038209160917;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 27996;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 962023729223982870;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 1064470260;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 147081557609;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 2439649222;
//         amt += y;
//         bondingCurve.buy{value: y}();
//         y = 4025603343;
//         amt += y;
//         bondingCurve.buy{value: y}();

//         // console.log(amt);
//         // uint256 value = 14173702303152637546;
//         // amt += value;
//         // bondingCurve.buy{value: value}();

//         y = 826297696847362454;
//         amt += y;
//         bondingCurve.buy{value: y}();

//         // assertEq(bondingCurve.unfulfilledEtherTillNextTier(), 1 ether);



//         // y = 582710270534675899;
//         // amt += y;
//         // bondingCurve.buy{value: y}();
//         // y = 4556434140615506758;
//         // amt += y;
//         // bondingCurve.buy{value: y}();
//         // y = 826297700872965797; 826297700872965797
//         // amt += y;
//         // bondingCurve.buy{value: y}();

//         uint256 n = bondingCurve.n_tier();
//         uint256 unfulfilled = bondingCurve.unfulfilledEtherTillNextTier();
        
//         console.log("Total:", amt, "\n");

//         console.log("Unfulfilled should be:", 1 ether - (amt % 1 ether));
//         console.log("But it is:", unfulfilled, "\n");

//         console.log("Tier should be:", amt - (amt % 1 ether));
//         console.log("But it is:", n, "\n");

//         // Logs:
//         // 20965442086043345418 -- total 20965442112023148454
//         // 34557913956654582 -- unfulfilled
//         // 20000000000000000000 -- tier
//     }
}

// [FAIL: invariant_divisibleTier replay failure]
// [Sequence]
//         sender=0x0000000000000000000000000000000000000619 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[2891347155755 [2.891e12]]
//         sender=0x00000000000000000000000000000000b5508aa9 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[137]
//         sender=0x00000000000000000000000000000000012500AB addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[33199395 [3.319e7]]
//         sender=0xb59714fED27d5a3d9aC07667C5bD4Bd8FE6F495a addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[210]
//         sender=0x000000000000000000000000000000071a607096 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[479]
//         sender=0xb58f61fAD1f253f5472D73a801DB42F9278fFebB addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[2]
//         sender=0x0000000000000000000000000000000000000A00 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[1]
//         sender=0x0000000000000000000000000000008901eae6bD addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[28913803559760000 [2.891e16]]
//         sender=0xCaeE40e42166e6b7F22E63354cCE0A47570fC5DD addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[4613]
//         sender=0x000000000000000000000000000000000000145b addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[997000000000000000 [9.97e17]]
//         sender=0x000000000000000000000000000000000fc2DC32 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[19430000 [1.943e7]]
//         sender=0xB4695e993dF1bF48D16fd7dac730677b98Ed7DD2 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[3]
//         sender=0x0000000000000000000000000000000000000161 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[2957397981 [2.957e9]]
//         sender=0x000000000000360D7AeeA093263EcC6E0ECb2918 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[1766]
//         sender=0x0000000000000000000000000000000000000a1b addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[3170000 [3.17e6]]
//         sender=0x000000000000000000000000000000000389A94D addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[3211736 [3.211e6]]
//         sender=0x02f2BE69224E7c213182ef1312a90e21a2618c1A addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[1317]
//         sender=0x00000000000000000000000000000000000008b8 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[4163653872 [4.163e9]]
//         sender=0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[9053245411 [9.053e9]]
//         sender=0x00000000000000000000000000000000aa8C217B addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[11244 [1.124e4]]
//         sender=0x00000000000000000000000000000000000013F8 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[5048]
//         sender=0x0d7008cB2108dF6649D5D8d04b9e6F62be57Ecf3 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[30]
//         sender=0x5122DD85BB3D85318f68a56724F770EB2eb5a053 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[28626266 [2.862e7]]
//         sender=0x00000000000000000000000000000037bD4404D5 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[11937580405141182 [1.193e16]]
//         sender=0x329A0A9D98c5dE9fe2819922A65399C5Bc600595 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[14456323 [1.445e7]]
//         sender=0x02eeBB55F960b334ce2e92c4FFbc4f42fF47c80C addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[121953207738874 [1.219e14]]
//         sender=0x00000000000000000000000000000000003fE207 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[3630]
//         sender=0x000000000000000000000000008ce72538620D66 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[25979801856 [2.597e10]]
//         sender=0x00000000000000000000000D75d07278827a529d addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[92]
//         sender=0x0000000000000000000000000000000000001181 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[658927908360 [6.589e11]]
//         sender=0xfcdAD9A251740D758e797CBCA779bcFA3bA863b4 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[234]
//         sender=0x000000000000000000000000000000003f520589 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[799404249395742 [7.994e14]]
//         sender=0x000000000000000000000000000000000000058d addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[6610004 [6.61e6]]
//         sender=0x00000000000000000000000000000000000014D3 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[95795065564217076 [9.579e16]]
//         sender=0x000000000000000000000000992ec4eFc2Cba148 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[1460]
//         sender=0xa48D6811C8bD341CD09D4602ba6bC65E5Ac7aAbC addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[261194 [2.611e5]]
//         sender=0x0000000000000000000000000000000000001528 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[1637055115 [1.637e9]]
//         sender=0xFBb55DF74996Ad68e6216AD114148E51e689E092 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[91685156439 [9.168e10]]
//         sender=0x00000000000000000000076477c40f9Ffa902Db3 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[2587]
//         sender=0x12B3B55fB5E2e1c37c9c5d2E7a51c662e65Ad71e addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[133435818874667250 [1.334e17]]
//         sender=0x0c3CA79E8F850bA3b28d720dd609226Bb9cFFFf7 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[15179 [1.517e4]]
//         sender=0x0000000000000000000000000000000000006d5C addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[2]
//         sender=0x0000000000000000000001FA8CCFf1BA932CC656 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[1849]
//         sender=0x00000000000000000000177F078285aDfAA7e357 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[1659860 [1.659e6]]
//         sender=0x000000000000000000000000000000000025A6e1 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[1]
//         sender=0x000000000000000000000000006Ea2351630DE80 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[185839115262 [1.858e11]]
//         sender=0x0000000000000000000000000000000245813dC1 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[27854045253403 [2.785e13]]
//         sender=0x0000000000000000000000009C6000f315a72611 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[510]
//         sender=0x000000000000000000000000000020B3dF89a5b2 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[157]
//         sender=0x0000000000000000000000000000000000000fBD addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[19202219 [1.92e7]]
//         sender=0x00000000000000000000019370dfaD0B83074Bfd addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[2097537592 [2.097e9]]
//         sender=0xCe503202F58fF5f19ddC7b2774Ac15E892dbc4F6 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[27906 [2.79e4]]
//         sender=0x89C88704AEd0C8202B654B0cD44fA74a7Ef8E432 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[671973852627494870 [6.719e17]]
//         sender=0x000000000000000000000000000000000285a3FE addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[1380881925064406 [1.38e15]]
//         sender=0x0254EEC0dFB1feFb9d64Ad16C8560BeE74B151Dc addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[1561]
//         sender=0x0fef10105fA2faAe0126114a169C64845d6126C9 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[737062167441790035 [7.37e17]]
//         sender=0x000000000000000000000000000000000000023A addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[166224734200903222 [1.662e17]]
//         sender=0x00000000000000000000000000000000000072Bf addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[40744015 [4.074e7]]
//         sender=0x0000000000000000000000000000000000000173 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[26026605148018 [2.602e13]]
//         sender=0x3ceaEA491Bc38174A7350b23401ECf1774ab2502 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[19260000 [1.926e7]]
//         sender=0x000000000000000000000000000000FB812E5A90 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[4058]
//         sender=0x000000000000000000000000000000008466F414 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[1741]
//         sender=0x00000000000000000000000000000015276D4926 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[30891 [3.089e4]]
//         sender=0x00000000000000000000000000000000dB07Fcd1 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[13990118434759 [1.399e13]]
//         sender=0x0000000000000000000000000D1EA7c82489cFAe addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[1765]
//         sender=0x601c0FeF24B267ea50e0dDf3a45655aFe006768d addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[3954581269 [3.954e9]]
//         sender=0x000000000000000000000000000010F7b661fe1A addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[1]
//         sender=0xA0024187cbAB9250c4d09Cc25Ae74A92610D7B9D addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[4247675890690783 [4.247e15]]
//         sender=0x000000000000000000000000000000000017a364 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[343356212307 [3.433e11]]
//         sender=0x000000000000000000000000d9e42e3C3546010b addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[3731420 [3.731e6]]
//         sender=0x000000000000000000000000000000000000171b addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[2369]
//         sender=0x0000000000000000000000004a351F28D7e7D8C3 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[33199394 [3.319e7]]
//         sender=0x000000000000000000000000000000B44037951A addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[29542878107903920 [2.954e16]]
//         sender=0x00000000000000000000000000000000010F15A6 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[962023755203784726 [9.62e17]]
//         sender=0x000000000000000000001ab8A4584F4e915ECeB9 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[3170000 [3.17e6]]
//         sender=0x000000000000000000000000000000B2249dFE00 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[35127986409344 [3.512e13]]
//         sender=0xc31dA4d237279E7Dc41349a065358e28bB4D136C addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[48479600 [4.847e7]]
//         sender=0x00000000000000000000000000000000003C8513 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[4072]
//         sender=0x000000000000000000000000000000000217e323 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[1693]
//         sender=0x626dE9a099aC3EBca27bD8D419Cae7cE5567B792 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[2]
//         sender=0x000000000000000000000000000000000052D842 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[207674 [2.076e5]]
//         sender=0x00000000000000000000000003e1D1E20F6a7B1A addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[87]
//         sender=0x000000000000000000000000000000B44037951A addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[37124682 [3.712e7]]
//         sender=0x0000000000000000000000000000000000000018 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[1]
//         sender=0x7e9B8482bd2aC7b3890FFc9B668dc5D738fe1De9 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[7846377 [7.846e6]]
//         sender=0xb90f476dBc7c8E767Ba668455e37BB9b33089e59 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[680658719 [6.806e8]]
//         sender=0x00000000000000000000000000000000000002F6 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[27]
//         sender=0x0000000000000000000000000010D96E0CA17c0f addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[345]
//         sender=0x00000000000000000000000000000812B26bA577 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[532113753339411831 [5.321e17]]
//         sender=0xeEB572B2AE48B763E14B5E7C100c7361241f8369 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[4081]
//         sender=0x1e66f26589E1DfA6158D2bCAc13297935c16c386 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[3857]
//         sender=0x0000000000000000000000000000000002367A4A addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[1287]
//         sender=0x0000000000000000000000000000000000000B1C addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[2]
//         sender=0x47b36AaDeB9afa22b60B6cCc2773462907e46BcE addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[8210144230706732945 [8.21e18]]
//         sender=0x000000000000000000000000000000000000071A addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[3]
//         sender=0x000000000000000000000000B2418d56e4E894Ca addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[3821400007878059 [3.821e15]]
//         sender=0x000000000000000000001Ab8a637dFc44Ba29bBf addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[21636599 [2.163e7]]
//         sender=0x00000000000000000000009a2925a2599338A2c0 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[5767]
//         sender=0x0000000000000000000000000a288F78C2Ef861a addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[60294702826 [6.029e10]]
//         sender=0x00000000000000000000000000000000000000e7 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[48938314 [4.893e7]]
//         sender=0x00000000000000000000000000000000029eDdAb addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[483]
//         sender=0x00000000000000000000000000000000a6F2AE3A addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[18190343400248 [1.819e13]]
//         sender=0x000000000000000000000cdbdf0db5926E3De9Ee addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[159433208708843134 [1.594e17]]
//         sender=0x00000000000000000000000000000037bD4404D5 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[4494984 [4.494e6]]
//         sender=0x0000000000000000000000000000000000000e52 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[6175]
//         sender=0x0000000000000000000017390B90AE216Bc8CB25 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[155282993297014036 [1.552e17]]
//         sender=0x0000000000000000000000000000000000000297 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[23459765679 [2.345e10]]
//         sender=0xAc698Bc7C0A9a5F31D03250463e96f7455f96236 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[3966227 [3.966e6]]
//         sender=0x4Cbec472A1005bc017D73744Fd15A452e2Ff5354 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[23678217 [2.367e7]]
//         sender=0x00000000000000000000000000000005cf59b30A addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[305980836557647035 [3.059e17]]
//         sender=0xcE40B69550dF86C3e99C2d25A833F59c2856dc70 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[2891347155755 [2.891e12]]
//         sender=0x000000000000000000000000000000003BBaff82 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[488192160216796 [4.881e14]]
//         sender=0x0000000000000000000000000000000000dc9603 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[408757808150 [4.087e11]]
//         sender=0x0000000000000000000000000000000C53C1209F addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[3821400007878058 [3.821e15]]
//         sender=0xAcF6838B7Fdd01626bc46E0f55A6ab1BC93d776e addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[1]
//         sender=0x0000000000000000000000000066B8F37E4965b1 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[3]
//         sender=0xAcBf26a737A154eC52c1967172583192a30c3bCF addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[4038209160917 [4.038e12]]
//         sender=0x00000000000000000000000000000000000009F0 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[27996 [2.799e4]]
//         sender=0x0000000000000000000000000000000000000800 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[962023729223982870 [9.62e17]]
//         sender=0x49EAF0b2004eFBA3FF0d2FFa1D586CCD4D391c97 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[1064470260 [1.064e9]]
//         sender=0x000000000000000000000073B732dfDA9E3cb70a addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[147081557609 [1.47e11]]
//         sender=0x0000000000000000000000000000000000011053 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[2439649222 [2.439e9]]
//         sender=0x0000000000000000000000000000000000dF2BCF addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[4025603343 [4.025e9]]
//         sender=0x000000000000000000000000000000598299B1ff addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[826297696847362454 [8.262e17]]
//         sender=0x000000000000000000000000000000000000053B addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[582710270534675899 [5.827e17]]
//         sender=0x00000000000000000000000000000000030c3D02 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[4556434140615506758 [4.556e18]]
//         sender=0x000000000000000000000000000000000667f9d7 addr=[test/DoxaBondingCurveInvariant.t.sol:DoxaBondingCurveInvariantTest]0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 calldata=handler_buy(uint256) args=[826297700872965797 [8.262e17]]
// invariant_divisibleTier() (runs: 1, calls: 1, reverts: 1)

// Encountered a total of 1 failing tests, 1 tests succeeded