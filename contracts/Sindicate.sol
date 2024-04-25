// https://sepolia.etherscan.io/address/0x8538d16f17332d3549ebb80657e541db92c1f898#code
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPool {
    function getUserAccountData(
        address user
    )
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

pragma solidity ^0.8.0;

contract Sindicate {
    IPool public pool;
    uint public limit = 2060000000000000000;
    constructor(address pool_) {
        pool = IPool(pool_);
    }

    function check(address[] memory user) public view returns (bool[] memory) {
        bool[] memory healthFactor = new bool[](user.length);
        uint256 healt;
        uint j;
        for (uint i = 0; i < user.length; i++) {
            (, , , , , healt) = pool.getUserAccountData(user[i]);
            if (healt < limit) {
                healthFactor[i] = true;
                j++;
            }
        }
        return healthFactor;
    }
    function changeLimit(uint newLimit) public {
        limit = newLimit;
    }
    function changeIPool(address newPool) public {
        pool = IPool(newPool);
    }
}
