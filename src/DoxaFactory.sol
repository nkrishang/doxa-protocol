// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {DoxaBondingCurve} from "./DoxaBondingCurve.sol";
import {LibClone} from "lib/solady/src/utils/LibClone.sol";

contract DoxaFactory {

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       STORAGE                              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice The implementation address of the DoxaBondingCurve contract.
    address public immutable implementation;

    /// @notice The DoxaBondingCurve contract registry mapping.
    mapping(address => bool) public registered;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CONSTRUCTOR                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    constructor() {
        implementation = address(new DoxaBondingCurve());
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       EVENTS                               */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Emitted when a token is created.
    event TokenCreated(address indexed tokenAddress, address indexed deployer, string name, string symbol);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CREATE TOKEN                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function predictTokenAddress(bytes32 _salt) public view returns (address tokenAddress) {
        return LibClone.predictDeterministicAddress(implementation, _salt, address(this));
    }

    function createToken(string memory _name, string memory _symbol, string memory _metadataURI, bytes32 salt) public payable returns (address tokenAddress) {
        tokenAddress = LibClone.cloneDeterministic(implementation, salt);
        DoxaBondingCurve(tokenAddress).initialize(_name, _symbol, _metadataURI);

        registered[tokenAddress] = true;

        emit TokenCreated(tokenAddress, msg.sender, _name, _symbol);
    }
}
