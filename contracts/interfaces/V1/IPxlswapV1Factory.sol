// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IPxlswapV1Factory {
    function getExchange(address) external view returns (address);
}
