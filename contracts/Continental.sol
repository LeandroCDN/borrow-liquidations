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
interface UiPoolDataProviderV3 {
    struct UserReserveData {
        address underlyingAsset;
        uint256 scaledATokenBalance;
        bool usageAsCollateralEnabledOnUser;
        uint256 stableBorrowRate;
        uint256 scaledVariableDebt;
        uint256 principalStableDebt;
        uint256 stableBorrowLastUpdateTimestamp;
    }

    function getUserReservesData(
        address provider,
        address user
    ) external view returns (UserReserveData[] memory, uint8);
}

pragma solidity ^0.8.0;

contract Continental {
    struct userData {
        address from;
        uint256 healtFactor;
    }

    IPool public pool;
    uint public maxLimit = 1050000000000000000;
    uint public minLimit = 0;

    constructor(address pool_) {
        pool = IPool(pool_);
    }

    function check(
        address[] memory user
    ) public view returns (userData[] memory) {
        userData[] memory healthFactor = new userData[](user.length);
        uint256 healt;
        uint j;
        for (uint i = 0; i < user.length; i++) {
            (, , , , , healt) = pool.getUserAccountData(user[i]);
            if (healt > minLimit && healt < maxLimit) {
                healthFactor[j] = userData(user[i], uint128(healt));
                j++;
            }
        }
        return healthFactor;
    }

    function checkMinTotalCollateralBase(
        address[] memory user,
        uint minTotalCollateralBase
    ) public view returns (userData[] memory) {
        userData[] memory healthFactor = new userData[](user.length);
        uint256 healt;
        uint j;
        uint256 totalCollateralBase;
        for (uint i = 0; i < user.length; i++) {
            (totalCollateralBase, , , , , healt) = pool.getUserAccountData(
                user[i]
            );
            if (
                healt > minLimit &&
                healt < maxLimit &&
                totalCollateralBase > minTotalCollateralBase
            ) {
                healthFactor[j] = userData(user[i], totalCollateralBase/1000000);
                j++;
            }
        }
        return healthFactor;
    }

    function fullCheck(
        address[] memory user,
        uint minTotalCollateralBase,
        uint floor,
        uint ceiling
    ) public view returns (userData[] memory) {
        userData[] memory healthFactor = new userData[](user.length);
        uint256 healt;
        uint j;
        uint256 totalCollateralBase;
        for (uint i = 0; i < user.length; i++) {
            (totalCollateralBase, , , , , healt) = pool.getUserAccountData(
                user[i]
            );
            if (
                healt > floor &&
                healt < ceiling &&
                totalCollateralBase > minTotalCollateralBase
            ) {
                healthFactor[j] = userData(user[i],totalCollateralBase/1000000);
                j++;
            }
        }
        return healthFactor;
    }

    function getUserReserve(
        address user,
        UiPoolDataProviderV3 poolDataProvider,
        address poolAddressesProvider
    ) public view returns (address[] memory, address[] memory) {
        // UiPoolDataProviderV3.UserReserveData[] memory reserveData;
        (UiPoolDataProviderV3.UserReserveData[] memory reserveData, ) = poolDataProvider.getUserReservesData(poolAddressesProvider, user);
        
        address[] memory collateralList = new address[](reserveData.length);
        address[] memory debtList = new address[](reserveData.length);
        for(uint i; i<reserveData.length;i++ ){
            if(reserveData[i].usageAsCollateralEnabledOnUser){
                collateralList[i] = reserveData[i].underlyingAsset;
            }
            if(reserveData[i].scaledVariableDebt > 0){
                debtList[i] = reserveData[i].underlyingAsset;
            }
        }

        return(collateralList,debtList);
    }

    function changeLimit(uint newMaxLimit, uint newMinLimit) public {
        maxLimit = newMaxLimit;
        minLimit = newMinLimit;
    }
    
    function changeIPool(address newPool) public {
        pool = IPool(newPool);
    }
}
