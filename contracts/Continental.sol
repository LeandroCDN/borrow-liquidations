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

contract Continental {
    struct userData{
        address from;
        uint128 healtFactor;
    }

    IPool public pool;
    uint public maxLimit = 100000000000000000;
    uint public minLimit = 0;

    constructor(address pool_) {
        pool = IPool(pool_);
    }

    function check(address[] memory user) public view returns (userData[] memory) {
        userData[] memory healthFactor = new userData[](user.length);
        uint256 healt;
        uint j;
        for (uint i = 0; i < user.length; i++) {
            (, , , , , healt) = pool.getUserAccountData(user[i]);
            //  (collateralValue, , , , , healt) = pool.getUserAccountData(user[i]);
            //  if (totalCollateralBase > X)=>
            if (healt > minLimit && healt < maxLimit) {
                healthFactor[j] = userData(user[i],uint128(healt));
                j++;
            }
        }
        return healthFactor;
    }

    function checkMinTotalCollateralBase(address[] memory user, uint minTotalCollateralBase) public view returns (userData[] memory) {
        userData[] memory healthFactor = new userData[](user.length);
        uint256 healt;
        uint j;
        uint256 totalCollateralBase;
        for (uint i = 0; i < user.length; i++) {
            (totalCollateralBase, , , , , healt) = pool.getUserAccountData(user[i]);
            if (healt > minLimit && healt < maxLimit && totalCollateralBase > minTotalCollateralBase) {
                healthFactor[j] = userData(user[i],uint128(healt));
                j++;
            }
        }
        return healthFactor;
    }

    function fullCheck(address[] memory user, uint minTotalCollateralBase, uint floor, uint ceiling) public view returns (userData[] memory) {
        userData[] memory healthFactor = new userData[](user.length);
        uint256 healt;
        uint j;
        uint256 totalCollateralBase;
        for (uint i = 0; i < user.length; i++) {
            (totalCollateralBase, , , , , healt) = pool.getUserAccountData(user[i]);
            if (healt > floor && healt < ceiling && totalCollateralBase > minTotalCollateralBase) {
                healthFactor[j] = userData(user[i],uint128(healt));
                j++;
            }
        }
        return healthFactor;
    }
     
    function changeLimit(uint newMaxLimit, uint newMinLimit) public {
        maxLimit = newMaxLimit;
        minLimit = newMinLimit;
    }
    function changeIPool(address newPool) public {
        pool = IPool(newPool);
    }
}
