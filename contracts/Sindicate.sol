// https://sepolia.etherscan.io/address/0x34b08ccf9620aed6d158bae65e85bb3bbe2c384a#code
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
    struct userData{
        address from;
        uint128 healtFactor;
    }

    IPool public pool;
    uint public limit = 1500000000000000000;

    constructor(address pool_) {
        pool = IPool(pool_);
    }

    function check(address[] memory user) public view returns (userData[] memory) {
        userData[] memory healthFactor = new userData[](user.length);
        uint256 healt;
        uint j;
        for (uint i = 0; i < user.length; i++) {
            (, , , , , healt) = pool.getUserAccountData(user[i]);
            if (healt < limit) {
                healthFactor[j] = userData(user[i],uint128(healt));
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
