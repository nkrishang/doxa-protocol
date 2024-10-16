// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IWETH {
    function approve(address spender, uint256 value) external returns (bool success);
    function deposit() external payable;
    function withdraw(uint256) external;
}
