// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IERC20 {
    function decimals() external  view  returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
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
interface IProtocolProvider{
    function getReserveConfigurationData(address asset) external view returns(uint,uint,uint,uint,uint,bool,bool,bool,bool,bool);
}

interface IDebIERC20 is IERC20{
    function UNDERLYING_ASSET_ADDRESS() external view returns(address);
}

interface IPool {
    function flashLoanSimple( address receiverAddress, address asset, uint256 amount, bytes calldata params, uint16 referralCode) external;
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

    function checkLiquidationReward(IDebIERC20 asset, address user, uint hf, IPriceOracle oracle, IProtocolProvider liquidationBonusProvider)public view returns(uint){
        // amount = asset(balanceOf(user));
        uint amount = asset.balanceOf(user);
        uint value = (oracle.getAssetPrice(asset.UNDERLYING_ASSET_ADDRESS())/100000000)*amount;
        (,,,uint liquidationBonus,,,,,,) = liquidationBonusProvider.getReserveConfigurationData(asset.UNDERLYING_ASSET_ADDRESS());
        uint reward = (value * liquidationBonus) / 10000;
        if(hf > 95){
            reward = reward/2;
        } 
        reward = (reward * 100)/ getDecimals(asset);
        return reward;
    }

    function getDecimals (IDebIERC20 asset) public view returns(uint){
        uint num = 1 * 10 ** asset.decimals();
        return num;
    }

    function getAmmon(address asset, uint amount, IPool pool ) public {
        bytes memory params = "0x0";
        require(getIfIsProfitable(), "BabaYaga does not do charity");
        pool.flashLoanSimple(address(this), asset, amount,params, 0);
    }   

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool){
        require(amount <= IDebIERC20(asset).balanceOf(address(this)), "Invalid balance, was the flashLoan successful?");
        uint flashPayment = (amount*105)/100;
        IDebIERC20(asset).approve(0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951,flashPayment*100);
        return true;
    }

    function getRewards(address asset) public {
        IERC20(asset).transfer(msg.sender,   IERC20(asset).balanceOf(address(this)));
    }

    function killWithAPencil() public {

    }
    
    function getLiquidationParams() public view {
        //return all liquidation param
    }  

    function getIfIsProfitable() public pure returns(bool){
        return true;
    }
}