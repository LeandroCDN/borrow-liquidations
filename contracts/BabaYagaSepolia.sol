// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
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
    function getAssetsPrices(address[] memory asset) external view returns(uint[] memory prices);// return with 8 decimals 1 usd=100000000
}
interface IProtocolProvider{
    function getReserveConfigurationData(address asset) external view returns(uint,uint,uint,uint,uint,bool,bool,bool,bool,bool);
}

interface IDebIERC20 is IERC20{
    function UNDERLYING_ASSET_ADDRESS() external view returns(address);
}

interface IPool {
    function flashLoanSimple( address receiverAddress, address asset, uint256 amount, bytes calldata params, uint16 referralCode) external;
    function liquidationCall(address collateral, address debt, address user, uint256 debtToCover, bool receiveAToken) external;
}

interface ISwapRouterV2{
     function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

contract BabaYagaSepolia {
    ISwapRouterV2 public swapContract;

    constructor (ISwapRouterV2 swapContract_) {
        swapContract=swapContract_;
    }

    function setSwapContract(ISwapRouterV2 swapContract_) public {
        swapContract = swapContract_;
    }

    function getUserReserve(
        address user,
        UiPoolDataProviderV3 poolDataProvider,
        address poolAddressesProvider
    ) public view returns (address[] memory, address[] memory, uint colLength,uint debtLenght) {
        (UiPoolDataProviderV3.UserReserveData[] memory reserveData, ) = poolDataProvider.getUserReservesData(poolAddressesProvider, user);
        
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

    function checkLiquidationReward(IDebIERC20 asset, address user, uint hf, IPriceOracle oracle, IProtocolProvider liquidationBonusProvider)public view returns(uint, uint,bool){
        // amount = asset(balanceOf(user));
        uint amount = asset.balanceOf(user);
        uint value = (oracle.getAssetPrice(asset.UNDERLYING_ASSET_ADDRESS())/100000000)*amount;
        (,,,uint liquidationBonus,,,,,,) = liquidationBonusProvider.getReserveConfigurationData(asset.UNDERLYING_ASSET_ADDRESS());
        uint reward = (value * liquidationBonus)/10000;
        uint netReward = (((value * liquidationBonus)/10000) - value);
        if(hf < 95){
            reward= reward/2;
            netReward= netReward/2;
        }
        reward = (reward * 100)/ getDecimals(asset);
        netReward = (netReward * 100)/ getDecimals(asset);
        
        return (reward,netReward,netReward>20);
    }

    function getDecimals (IDebIERC20 asset) public view returns(uint){
        uint num = 1 * 10 ** asset.decimals();
        return num;
    }

    function getAmmonAndGetReward(address asset, uint amount, IPool pool, address colAsset, address user,bool bridgeSwap, bytes memory path) public {
        bytes memory params = abi.encode(colAsset, user, address(pool), bridgeSwap, path);
        pool.flashLoanSimple(address(this), asset, amount,params, 0);
        //check balanceValue and make balanceValue > minProfitable
        getRewards(msg.sender,asset);
    }  

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool){
        require(amount <= IDebIERC20(asset).balanceOf(address(this)), "Invalid balance, was the flashLoan successful?");
        (address colAsset, address user, address pool,bool bridgeSwap,bytes memory path) = abi.decode(params, ( address, address, address, bool, bytes));

        if(!bridgeSwap){
            killWithAPencil(colAsset, asset, user, pool);
        }else{
            killWithABridge(colAsset, asset, user, pool,path);
        }

        // uint flashPayment = (amount*(10000+premium))/10000;
        // IDebIERC20(asset).approve(address(pool),flashPayment*100);
        return true;
    }

    function getRewards(address to, address asset) public {
        IERC20(asset).transfer(to, IERC20(asset).balanceOf(address(this)));
    }

    function killWithAPencil(address colAsset,address debtAsset,address user, address pool) public {
        uint debtToCover = 9999999 * 1 ether;
        // IDebIERC20(debtAsset).approve(address(pool),debtToCover);
        IPool(pool).liquidationCall(colAsset, debtAsset, user, debtToCover, false);

        address[] memory path = new address[](2);
        path[0] = colAsset;
        path[1] = debtAsset;
        swap(IERC20(colAsset).balanceOf(address(this)), path);
    }

    function killWithABridge(address colAsset,address debtAsset,address user, address pool, bytes memory params) public {
        IPool(pool).liquidationCall(colAsset, debtAsset, user, 9999999999999999999999999999, false);
        swapBridge(params,IERC20(colAsset).balanceOf(address(this)));
    }

    function swap(uint amountIn, address[] memory path) internal { 
        // require(IERC20(path[0]).approve(address(swapContract), amountIn), 'approve failed.');
        ISwapRouterV2.ExactInputSingleParams memory params = ISwapRouterV2.ExactInputSingleParams({
            tokenIn: path[0],
            tokenOut: path[1],
            fee: 100,
            recipient: address(this),
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        uint16[3] memory fees = [100, 500, 2500];
        for(uint i; i <fees.length ; i++){
            params.fee = uint24(fees[i]);
            try swapContract.exactInputSingle(params) returns (uint256 ){
                i = 4;
            } catch {
            }
        }
    }

    function swapBridge(bytes memory path,uint amountIn) internal {
        ISwapRouterV2.ExactInputParams memory params = ISwapRouterV2.ExactInputParams({
            path: path,
            recipient: address(this),
            amountIn: amountIn,
            amountOutMinimum: 0
        });
        swapContract.exactInput(params);
    }
    
    function approvePool(address manager, address[] memory assets) public {
        uint approvedAmmount = 9999999 * 1 ether ;
        for (uint i; i< assets.length; i++){
            IERC20(assets[i]).approve(address(manager),approvedAmmount);
        }
    }

    function getCollateralBallanceAndValue(address[] memory aAsset, address user,IPriceOracle oracle) public view returns(uint[] memory, uint[] memory){
        uint[] memory balances = new uint[](aAsset.length);
        uint[] memory value = new uint[](aAsset.length);
        for(uint i; i < aAsset.length; i++){
           balances[i] = IERC20(aAsset[i]).balanceOf(user);
           value[i] = (oracle.getAssetPrice(aAsset[i])/100000000) * balances[i];
           value[i] = value[i]/getDecimals(IDebIERC20(aAsset[i]));
        }
        return (balances,value);
    }
    
    function getCollateralBallanceAndValueAutomated(UiPoolDataProviderV3 poolDataProvider, address poolAddressesProvider, address user,IPriceOracle oracle) public view returns(uint[] memory, uint[] memory){
        (address[] memory aAsset, ,uint colLength,)=  getUserReserve(user,poolDataProvider,poolAddressesProvider);
        uint[] memory balances = new uint[](colLength);
        uint[] memory value = new uint[](colLength);

        //(IDebIERC20[] memory aAsset, )=  getUserReserve(user,poolDataProvider,poolAddressesProvider);
        // for { if aAsset[i]!=address(0) =>}
        for(uint i; i < aAsset.length; i++){
           if(aAsset[i] != address(0)){
             balances[i] = IERC20(aAsset[i]).balanceOf(user);
             value[i] = (oracle.getAssetPrice(aAsset[i])/100000000) * balances[i];
             value[i] = value[i]/getDecimals(IDebIERC20(aAsset[i]));
           } 
        }
        return (balances,value);
    }

     function pathMaker(address address1in,uint24 fee,address address1out,uint24 fee2 ,address bridge)public pure returns(bytes memory){
        bytes memory path = abi.encodePacked(address1in, fee,bridge,fee2,address1out);
        return path;
    }
}