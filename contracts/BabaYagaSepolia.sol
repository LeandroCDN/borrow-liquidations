// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3SepoliaAssets} from "./addresses/AaveV3Sepolia.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract BabaYagaSepolia {
    address[] public aTokens;
    event TokensWritten(address indexed token, address indexed user, uint256 value);

    constructor(address[] memory _aTokens) {
        aTokens = _aTokens;
    }

    function checkBalances(address user) external view returns(uint[] memory){
        uint[] memory aBalances = new userData[](aTokens.length);
        IERC20 token;
        for (uint256 i = 0; i < aTokens.length; i++) {
            token = IERC20(aTokens[i]);
            aBalances[i] = token.balanceOf(user);
        }
        return aBalances;
    }

    function checkReward(address from) public view returns(uint){
        uint[] memory aBalances = new userData[](aTokens.length);
        aBalances = checkBalances(user);
        uint totalProfit;
        for(uint i; i < aTokens.length; i++){
            
        }
    }
}


/*
import {AaveV3SepoliaAssets} from "./addresses/AaveV3Sepolia.sol":

address internal constant DAI_A_TOKEN = 0x29598b72eb5CeBd806C5dCD549490FdA35B13cD8;
address internal constant LINK_A_TOKEN = 0x3FfAf50D4F4E96eB78f2407c090b72e86eCaed24;
address internal constant USDC_A_TOKEN = 0x16dA4541aD1807f4443d92D26044C1147406EB80;
address internal constant WBTC_A_TOKEN = 0x1804Bf30507dc2EB3bDEbbbdd859991EAeF6EefF;
address internal constant WETH_A_TOKEN = 0x5b071b590a59395fE4025A0Ccc1FcC931AAc1830;
address internal constant USDT_A_TOKEN = 0xAF0F6e8b0Dc5c913bbF4d14c22B4E78Dd14310B6;
address internal constant AAVE_A_TOKEN = 0x6b8558764d3b7572136F17174Cb9aB1DDc7E1259;
address internal constant EURS_A_TOKEN = 0xB20691021F9AcED8631eDaa3c0Cd2949EB45662D;
address internal constant GHO_A_TOKEN = 0xd190eF37dB51Bb955A680fF1A85763CC72d083D4;
*/