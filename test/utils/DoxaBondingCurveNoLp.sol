// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "lib/solady/src/tokens/ERC20.sol";
import {FixedPointMathLib} from "lib/solady/src/utils/FixedPointMathLib.sol";

import {IWETH} from "src/interface/IWETH.sol";
import {IUniswapV2Router01} from "src/interface/IUniswapV2Router01.sol";

contract DoxaBondingCurveNoLp is ERC20 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CONSTANTS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice The decay rate for the token amount sold per 1 ether.
    uint256 private constant DECAY_RATE = 0.997 ether;

    /// @notice The initial token amount sold per 1 ether before any decay.
    uint256 private constant A = 10_000 ether;

    /// @notice The maximum ether that can be used to buy tokens in one transaction.
    ///         This limits one transaction from buying an arbitrary amount of discounted tokens.
    uint256 private constant MAX_VALUE = 10 ether;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       STORAGE                              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Name of the token.
    string private name_;

    /// @notice Symbol of the token.
    string private symbol_;

    /// @notice Metadata URI of the token.
    string private metadataURI_;

    /// @notice The current tier.
    /// @dev Invariant: tier == etherSentToBuyInLifetime - (etherSentToBuyInLifetime % 1 ether)
    uint128 public tier;

    /// @notice The ether that can be used to buy tokens at the current decay factor
    /// @dev Invariant: unfulfilledEtherInTier == 1 ether - (etherSentToBuyInLifetime % 1 ether)
    uint128 public unfulfilledEtherInTier = 1 ether;

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

    constructor(string memory _name, string memory _symbol, string memory _metadataURI) {
        name_ = _name;
        symbol_ = _symbol;
        metadataURI_ = _metadataURI;
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

    /// @dev Returns the metadata URI of the token.
    function metadataURI() public view returns (string memory) {
        return metadataURI_;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       BUY TOKENS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice Buy tokens from the bonding curve in exchange for all ether sent to the function.
     *
     * @dev The amount of tokens sold per 1 ether is calculated as (A * (0.997)^tier)
     *
     *      The contract deposits the sent ether (K) and (K * A * (0.997)^MAX_LP_TIER)
     *      amount of tokens as liquidity to the AMM.
     *
     * @return amountOut The amount of tokens minted to the caller in exchange for all ether sent.
     */
    function buy() public payable returns (uint256 amountOut) {

        // Get the current tier.
        uint256 n = tier;

        // Get the ether value sent.
        uint256 value = msg.value;
        if (value == 0) {
            revert ZeroValueSent();
        }
        if (value > MAX_VALUE) {
            revert OverMaxValueSent();
        }

        // 1. Calculate amountOut for the unfulfilled ether in the current tier using the current decay rate.
        uint256 unfulfilled = unfulfilledEtherInTier;
        
        /**
         * Invariant: `unfulfilledEtherInTier` is never 0.
         * 
         * This if-block is necessary only if 0 < unfulfilled eth < 1 ether. Else, this block's calculation
         * is accounted for by the sum of the geometric series in the second if-block.
         */
        if (unfulfilled < 1 ether) {
            // Calculate decay = (0.997)^n
            uint256 decay = uint256(FixedPointMathLib.powWad(int(DECAY_RATE), int(n)));
            
            if(value < unfulfilled) {
                // Update amountOut += (A * decay * value)
                amountOut += FixedPointMathLib.mulWad(value, FixedPointMathLib.mulWad(A, decay));
                
                // Update unfulfilled ether in tier
                unfulfilled -= value;

                // Update value
                value = 0;
            } else {
                // Update amountOut += (A * decay * unfulfilled)
                amountOut += FixedPointMathLib.mulWad(unfulfilled, FixedPointMathLib.mulWad(A, decay));

                // Update value
                value -= unfulfilled;

                // Update tier
                n += 1 ether;

                // Reset unfulfilled ether in tier
                unfulfilled = 1 ether;
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

            // Update amountOut += (A * decay * value) where 0 < value < 1
            amountOut += FixedPointMathLib.mulWad(value, FixedPointMathLib.mulWad(A, decay));

            // Update unfulfilled ether in tier
            unfulfilled = 1 ether - value;
        }

        // Store updated tier
        tier = uint128(n);

        // Store unfulfilled ether in tier
        unfulfilledEtherInTier = uint128(unfulfilled);

        // Mint tokens
        _mint(msg.sender, amountOut);
        
        emit BuyTokens(msg.sender, msg.value, amountOut);
    }
}
