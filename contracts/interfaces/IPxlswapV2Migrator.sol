// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IPxlswapV2Migrator {
    function migrate(
        address token,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external;
}
