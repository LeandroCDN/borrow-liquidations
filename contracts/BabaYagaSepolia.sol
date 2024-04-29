// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

contract BabaYagaSepolia {
    function getUserReserve(
        address user,
        UiPoolDataProviderV3 poolDataProvider,
        address poolAddressesProvider
    ) public view returns (address[] memory, address[] memory) {
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

    function checkLiquidationReward()public view returns(uint){
        // reserveData[i].usageAsCollateralEnabledOnUser must be true!
        // debtAssetPrice  = aaveoracle.getAssetsPrices(address[] calldata assets)
        // (collateralValue,,,,) = pool.getUserAccountData(user[i]);
        // - normalize decimals
        // (collateralValue-debtAssetPrice)/2 = MinReward
        // netMinReward = MinReward - feesCosts(swaps-txExecutions-FloansFees)
        // if (netMinReward > MinViableProfit) => Execute
    }
}


/*
Calculating profitability vs gas cost
One way to calculate the profitability is the following:

Store and retrieve each collateral's relevant details such as address, decimals used and liquidation bonus.
liquidation bonus: https://docs.aave.com/developers/core-contracts/pool#getconfiguration
liquidation bonus: https://docs.aave.com/developers/core-contracts/aaveprotocoldataprovider#getliquidationprotocolfee
ProtocolDataProvider -> PoolDataProvider
Get the user's collateral balance (aTokenBalance).

Get the asset's price according to the Aave's oracle contract using getAssetPrice().

The maximum collateral bonus received on liquidation is given by the maxAmountOfCollateralToLiquidate * (1 - liquidationBonus) * collateralAssetPriceEth

The maximum cost of your transaction will be you gas price multiplied by the amount of gas used. You should be able to get a good estimation of the gas amount used by calling estimateGas via your web3 provider.

Your approximate profit will be the value of the collateral bonus (4) minus the cost of your transaction (5).
*/