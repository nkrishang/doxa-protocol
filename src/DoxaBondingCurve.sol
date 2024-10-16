// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "lib/solady/src/tokens/ERC20.sol";
import {FixedPointMathLib} from "lib/solady/src/utils/FixedPointMathLib.sol";

import {IWETH} from "src/interface/IWETH.sol";
import {IUniswapV2Router01} from "src/interface/IUniswapV2Router01.sol";

contract DoxaBondingCurve is ERC20 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CONSTANTS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice The decay rate for the token amount per 1 ether.
    uint256 private constant DECAY_RATE = 0.997 ether;

    /// @notice The token amount constant of the bonding curve equation.
    uint256 private constant A = 10_000 ether;

    /// @notice The maximum ether that can be used to buy tokens in one transaction.
    ///         This limits one transaction from buying an arbitrary amount of discounted tokens.
    uint256 private constant MAX_VALUE = 10 ether;

    /// @notice If the contract balance exceeds this amount in a buy transaction, the full contract 
    ///         balance will be deposited as liquidity with the proportionate amount of tokens.
    uint256 private constant LIQUIDITY_THRESHOLD = 1 ether;

    /// @notice The amount of token to LP: (10_000 * (0.997)^100) * 1 ether
    uint256 private constant LP_AMOUNT_PER_ETHER = 7404842595397826248704;

    /// @notice The address of the WETH9 contract on Base.
    address private constant WETH = 0x4200000000000000000000000000000000000006;

    /// @notice The address of the Uniswap V2 Router contract on Base.
    address private constant UNISWAP_V2_ROUTER = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       STORAGE                              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Name of the token.
    string private name_;

    /// @notice Symbol of the token.
    string private symbol_;

    /// @notice The current tier.
    /// @dev Invariant: n_tier % 1 ether == 0
    uint256 public n_tier;

    /// @notice The ether that can be used to buy tokens at the current decay factor
    /// @dev Invariant: 0 < unfulfilledEtherTillNextTier <= 1 ether
    uint256 public unfulfilledEtherTillNextTier = 1 ether;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       EVENTS                               */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Event emitted when a buyer buys tokens in exchange for ether.
    event BuyTokens(address indexed buyer, uint256 tokenAmount, uint256 etherAmount);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ERRORS                               */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Error: Zero msg.value sent to buy()
    error ZeroValueSent();

    /// @notice Error: msg.value sent to buy() is greater than MAX_VALUE
    error OverMaxValueSent();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CONSTRUCTOR                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    constructor(string memory _name, string memory _symbol) {
        name_ = _name;
        symbol_ = _symbol;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ERC20 METADATA                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the name of the token.
    function name() public view override returns (string memory) {
        return name_;
    }

    /// @dev Returns the symbol of the token.
    function symbol() public view override returns (string memory) {
        return symbol_;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       BUY TOKENS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice Buy tokens from the bonding curve in exchange for all ether sent to the function.
     *
     * @dev The amount of tokens owed per 1 ether sent is calculated as (A * (NEXT_PRICE_BPS)^tier) / (MAX_BPS)^tier.
     *
     *      The contract deposits the sent ether (K) and (K * A * (NEXT_PRICE_BPS)^MAX_LP_TIER) / (MAX_BPS)^MAX_LP_TIER
     *      amount of tokens as liquidity to the AMM.
     *
     * @return amountOut The amount of tokens minted to the caller in exchange for all ether sent.
     */
    function buy() public payable returns (uint256 amountOut) {

        // Get the current tier.
        uint256 n = n_tier;

        // Get the ether value sent.
        uint256 value = msg.value;
        if (value == 0) {
            revert ZeroValueSent();
        }
        if (value > MAX_VALUE) {
            revert OverMaxValueSent();
        }

        // 1. Calculate amountOut for the unfulfilled ether in the current tier using the current decay rate.
        uint256 unfulfilled = unfulfilledEtherTillNextTier;
        
        /**
         * Invariant: `unfulfilledEtherTillNextTier` is never 0 since we calculate (at the end of the function) that:
         * 
         * ```
         * unfulfilledEtherTillNextTier = 1 ether - value
         * ```
         * 
         * If (value >= 1 ether) at this point, something has gone wrong.
         * 
         * Therefore, this if-block is necessary only if 0 < unfulfilled eth < 1 ether. Else, this block's calculation
         * is accounted for by the sum of the geometric series in the second if-block.
         */
        if (unfulfilled < 1 ether) {
            // Calculate decay = (0.997)^n
            uint256 decay = uint256(FixedPointMathLib.powWad(int(DECAY_RATE), int(n)));
            
            // Update amountOut += (A * (0.997)^n) * unfulfilled where 0 < unfulfilled < 1
            if(value < unfulfilled) {
                amountOut += FixedPointMathLib.mulWad(value, FixedPointMathLib.mulWad(A, decay));
                
                // Store unfulfilled ether till next tier.
                unfulfilledEtherTillNextTier = unfulfilled - value;
                value = 0;
            } else {
                amountOut += FixedPointMathLib.mulWad(unfulfilled, FixedPointMathLib.mulWad(A, decay));

                // Update value
                value -= unfulfilled;

                // Update tier
                n += 1 ether;
            }
        }

        // 2. Calculate amountOut for the next consecutive `m` tiers.
        uint256 m = value - (value % 1 ether);
        if(m > 0) {
            // A * (0.997)^n
            uint256 firstTerm = FixedPointMathLib.mulWad(A, uint256(FixedPointMathLib.powWad(int(DECAY_RATE), int(n))));
            // 1 - 0.997^m
            uint256 numerator = 1 ether - uint256(FixedPointMathLib.powWad(int(DECAY_RATE), int(m)));
            // 1 - 0.997
            uint256 denominator = 1 ether - DECAY_RATE;

            // Update amountOut += sum where sum = A * (0.997)^n * (1 - 0.997^m) / (1 - 0.997)
            amountOut += FixedPointMathLib.divWad(FixedPointMathLib.mulWad(firstTerm, numerator), denominator);

            // Update value
            value -= m;

            // Update tier
            n += m;
        }

        // 3. Calculate amountOut for the remainder in the updated tier.
        if (value > 0) {
            // Calculate decay = (0.997)^n
            uint256 decay = uint256(FixedPointMathLib.powWad(int(DECAY_RATE), int(n)));

            // Update amountOut += (A * (0.997)^n) * value where 0 < value < 1
            amountOut += FixedPointMathLib.mulWad(value, FixedPointMathLib.mulWad(A, decay));

            // Store unfulfilled ether till next tier.
            unfulfilledEtherTillNextTier = 1 ether - value;
        }

        // Store updated tier
        n_tier = n;

        // Mint tokens
        _mint(msg.sender, amountOut);

        {
            if(address(this).balance > LIQUIDITY_THRESHOLD) {
                // Deposit msg.value and LP_AMOUNT of tokens into AMM pool.
                uint256 etherLp = address(this).balance ;
                uint256 tokenLp = FixedPointMathLib.mulWad(etherLp, LP_AMOUNT_PER_ETHER);
    
                // Approve router to use ether LP
                IWETH(WETH).deposit{value: etherLp}();
                IWETH(WETH).approve(UNISWAP_V2_ROUTER, etherLp);
    
                // Approve router to use token LP
                _mint(address(this), tokenLp);
                this.approve(UNISWAP_V2_ROUTER, tokenLp);
    
                IUniswapV2Router01(UNISWAP_V2_ROUTER).addLiquidity({
                    tokenA: WETH,
                    tokenB: address(this),
                    amountADesired: etherLp,
                    amountBDesired: tokenLp,
                    amountAMin: etherLp,
                    amountBMin: 0,
                    to: address(this),
                    deadline: block.timestamp
                });
            }
        }
        
        emit BuyTokens(msg.sender, msg.value, amountOut);
    }
}
