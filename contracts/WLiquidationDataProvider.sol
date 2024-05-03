// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function decimals() external  view  returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
interface IDebIERC20 is IERC20{
    function UNDERLYING_ASSET_ADDRESS() external view returns(address);
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
 
interface IPriceOracle{
    function getAssetPrice(address asset) external view returns(uint);// return with 8 decimals 1 usd=100000000
}

// return liquidation Bonus for a asset
interface IProtocolDataProvider{
    struct TokenData {
        string symbol;
        address tokenAddress;
     }
    function getReserveConfigurationData(address asset) external view returns(uint,uint,uint,uint,uint,bool,bool,bool,bool,bool);
    function getAllReservesTokens() external view returns(TokenData[] memory);
    function getReserveTokensAddresses(address asset)external view returns(address, address, address);
}

interface IPool {
    function getUserAccountData(address user)external view returns (
        uint256 totalCollateralBase,
        uint256 totalDebtBase,
        uint256 availableBorrowsBase,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    );
}

contract WLiquidationDataProvider {
    IPool public Pool;
    IProtocolDataProvider public ProtocolDataProvider;
    IPriceOracle public Oracle;
    UiPoolDataProviderV3 public PoolDataProviderV3;
    address public PoolAddressesProvider ;

    constructor(IPool pool_,IProtocolDataProvider protocolDataProvider_, IPriceOracle oracle_,UiPoolDataProviderV3 poolDataProviderV3_, address poolAddressesProvider_){
        Pool = pool_;
        ProtocolDataProvider = protocolDataProvider_;
        Oracle = oracle_;
        PoolDataProviderV3 = poolDataProviderV3_;
        PoolAddressesProvider = poolAddressesProvider_;
    }

    function getUserReservesData(address user) external view returns(UiPoolDataProviderV3.UserReserveData[] memory, uint8){
        return PoolDataProviderV3.getUserReservesData(PoolAddressesProvider, user);
    }

    function getAssetPrice(address asset) public view returns(uint){
        return Oracle.getAssetPrice(asset)/1000000;
    }

    function getReserveConfigurationData(address asset) external view returns(uint,uint,uint,uint,uint,bool,bool,bool,bool,bool){
        return ProtocolDataProvider.getReserveConfigurationData(asset);
    }

    function getAllReservesTokens() external view returns(IProtocolDataProvider.TokenData[] memory){
        return ProtocolDataProvider.getAllReservesTokens();
    }

    function getReserveTokensAddresses(address asset)external view returns(address, address, address){
        return ProtocolDataProvider.getReserveTokensAddresses(asset);
    }

    function getUserAccountData(address user)external view returns (
        uint256 totalCollateralBase,
        uint256 totalDebtBase,
        uint256 availableBorrowsBase,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    ){
        return Pool.getUserAccountData(user);
    }

    function getUserReserve(address user) public view returns (address[] memory, address[] memory, uint colLength,uint debtLenght) {
        (UiPoolDataProviderV3.UserReserveData[] memory reserveData, ) = PoolDataProviderV3.getUserReservesData(PoolAddressesProvider, user);
        
        address[] memory collateralList = new address[](reserveData.length);
        address[] memory debtList = new address[](reserveData.length);
        for(uint i; i<reserveData.length;i++ ){
            if(reserveData[i].usageAsCollateralEnabledOnUser){
                collateralList[i] = reserveData[i].underlyingAsset;
                colLength++;
            }
            if(reserveData[i].scaledVariableDebt > 0){
                debtList[i] = reserveData[i].underlyingAsset;
                debtLenght++;
            }
        }
        address[] memory fixedCollateralList = new address[](colLength);
        address[] memory fixedDebtList = new address[](debtLenght);
        uint j;
        uint n;
        for(uint i; i<reserveData.length;i++ ){
            if(collateralList[i] !=address(0)){
                fixedCollateralList[j] =collateralList[i];
                j++;
            }   
            if(debtList[i] !=address(0)){
                fixedDebtList[n] =debtList[i];
                n++;
            }   
        }
        return(fixedCollateralList,fixedDebtList,colLength,debtLenght);
    }

    function getBalances(address user, address[] memory assets) public view returns (uint[] memory){
        uint[] memory balances = new uint[](assets.length);
        for(uint i; i<balances.length;i++ ){
            balances[i] = IERC20(assets[i]).balanceOf(user);
        }
        return balances;
    }

    function changeVars(IPool pool_,IProtocolDataProvider protocolDataProvider_, IPriceOracle oracle_,UiPoolDataProviderV3 poolDataProviderV3_, address poolAddressesProvider_) public {
        Pool = pool_;
        ProtocolDataProvider = protocolDataProvider_;
        Oracle = oracle_;
        PoolDataProviderV3 = poolDataProviderV3_;
        PoolAddressesProvider = poolAddressesProvider_;
    }
}

// sepolia constructor:
/*
 POOL_:0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951
 PROTOCOLDATAPROVIDER_:0x3e9708d80f7B3e43118013075F7e95CE3AB31F31
 ORACLE_:0x2da88497588bf89281816106C7259e31AF45a663
 POOLDATAPROVIDERV3_:0x69529987FA4A075D0C00B0128fa848dc9ebbE9CE
 POOLADDRESSESPROVIDER_:0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A

*/