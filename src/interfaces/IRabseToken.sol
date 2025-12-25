//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.19;

interface IRebaseToken {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    // function balance0f(address user) external view returns (uint256);
    // function principalBalanceOf(address user) external view returns (uint256);
    // function getUserInterestRate(address user) external view returns (uint256);
}
