// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "lib/solady/src/tokens/ERC20.sol";
import {Initializable} from "lib/solady/src/utils/Initializable.sol";
import {FixedPointMathLib} from "lib/solady/src/utils/FixedPointMathLib.sol";

import {IWETH} from "src/interface/IWETH.sol";
import {IUniswapV2Router01} from "src/interface/IUniswapV2Router01.sol";

contract DoxaBondingCurve is ERC20, Initializable {
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

    /// @notice If the contract balance exceeds this amount in a buy transaction, the full contract 
    ///         balance will be deposited as liquidity with the proportionate amount of tokens.
    uint256 private constant LP_THRESHOLD = 1 ether;

    /// @notice The amount of token to LP: (10_000 * (0.997)^100) * 1 ether = ~7404.8425 tokens.
    uint256 private constant LP_AMOUNT_PER_ETHER = 7404842595397826248704;

    /// @notice The tier after which no LP is provided but a buyback can be initiated
    uint256 private constant MAX_LP_TIER = 100 ether;

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

    /// @notice Metadata URI of the token.
    string private metadataURI_;

    /// @notice The current tier.
    /// @dev Invariant: tier == etherSentToBuyInLifetime - (etherSentToBuyInLifetime % 1 ether)
    uint128 public tier;

    /// @notice The ether that can be used to buy tokens at the current decay factor
    /// @dev Invariant: unfulfilledEtherInTier == 1 ether - (etherSentToBuyInLifetime % 1 ether)
    uint128 public unfulfilledEtherInTier;

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

    /// @notice Error: buybacks not enabled.
    error BuybackDisabled();

    /// @notice Error: contract has zero ether balance.
    error ZeroEtherBalance();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CONSTRUCTOR                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    constructor() {
        _disableInitializers();
    }
    
    function initialize(string memory _name, string memory _symbol, string memory _metadataURI) public initializer {
        name_ = _name;
        symbol_ = _symbol;
        metadataURI_ = _metadataURI;
        unfulfilledEtherInTier = 1 ether;
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

    /// @notice Returns the amount of tokens that will be minted in exchange for the given amount of ether.
    function getAmountOut(uint256 etherAmount) public view returns (uint256 amountOut, uint256 newTier, uint256 newUnfulfilledEtherInTier) {
        // Get the current tier.
        uint256 n = tier;

        // Get the ether value sent.
        uint256 value = etherAmount;
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

        // Return updated tier
        newTier = uint128(n);

        // Return unfulfilled ether in tier
        newUnfulfilledEtherInTier = uint128(unfulfilled);
    }

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
        uint256 n_initial = tier;

        (uint256 amountOutTokens, uint256 newTier, uint256 newUnfulfilledEtherInTier) = getAmountOut(msg.value);

        // Return amount of tokens
        amountOut = amountOutTokens;

        // Store updated tier
        tier = uint128(newTier);

        // Store unfulfilled ether in tier
        unfulfilledEtherInTier = uint128(newUnfulfilledEtherInTier);

        // Mint tokens
        _mint(msg.sender, amountOut);

        // Provide liquidity in Uniswap V2
        {            
            if(address(this).balance >= LP_THRESHOLD && n_initial < MAX_LP_TIER) {
                
                // Deposit contract balance and proportionate tokens into pool.
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
        
        emit BuyTokens(msg.sender, amountOut, msg.value);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       BUYBACK                              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Buyback tokens from Uniswap V2 using contract balance and burn them.
    function buyback() external {

        if (tier < MAX_LP_TIER) {
            revert BuybackDisabled();
        }

        uint256 bal = address(this).balance;
        if (bal == 0) {
            revert ZeroEtherBalance();
        }

        // Approve router to use ether.
        IWETH(WETH).deposit{value: bal}();
        IWETH(WETH).approve(UNISWAP_V2_ROUTER, bal);
        
        // Send tokens to dummy burn address in order to later burn tokens.
        address recipient = 0x000000000000000000000000000000000000dEaD;

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        // Use all the contract balance for whatever amount of tokens that can be bought.
        uint256[] memory amounts = IUniswapV2Router01(UNISWAP_V2_ROUTER).swapExactTokensForTokens({
            amountIn: bal,
            amountOutMin: 0,
            path: path,
            to: recipient,
            deadline: block.timestamp
        });

        // Burn the bought tokens.
        _burn(recipient, amounts[1]);
    }
}
