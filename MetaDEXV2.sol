// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MetaDEXV2 is Ownable {
    IERC20 public trybToken; 
    address public teamWallet;
    address public stakingWallet;
    
    mapping(string => uint256) public oraclePrices; 
    
    struct Asset {
        IERC20 tokenContract;
        bool isActive;
    }
    mapping(string => Asset) public assets;

    event AssetAdded(string assetName, address tokenAddress);
    event PriceUpdated(string assetName, uint256 newPrice);
    event Trade(address indexed buyer, string assetName, uint256 trybAmount, uint256 assetAmount);
    event FeeDistributed(uint256 teamFee, uint256 stakingFee, uint256 autoLiquidityFee);

    constructor(address _tryb, address _teamWallet, address _stakingWallet) Ownable(msg.sender) {
        trybToken = IERC20(_tryb);
        teamWallet = _teamWallet;
        stakingWallet = _stakingWallet;
    }

    function addAsset(string memory assetName, address tokenAddress, uint256 initialPrice) external onlyOwner {
        assets[assetName] = Asset({ tokenContract: IERC20(tokenAddress), isActive: true });
        oraclePrices[assetName] = initialPrice;
        emit AssetAdded(assetName, tokenAddress);
    }

    function updateOraclePrice(string memory assetName, uint256 newPrice) external onlyOwner {
        require(assets[assetName].isActive, "Urun markette aktif degil");
        oraclePrices[assetName] = newPrice;
        emit PriceUpdated(assetName, newPrice);
    }

    // V2: SADECE ALIŞ MOTORU
    function buyAsset(string memory assetName, uint256 trybAmount) external {
        require(assets[assetName].isActive, "Urun markette bulunamadi");
        require(trybAmount > 0, "Sifirdan buyuk bir miktar girin");
        
        uint256 currentPrice = oraclePrices[assetName];
        require(currentPrice > 0, "Oracle fiyat verisi hatali");

        require(trybToken.transferFrom(msg.sender, address(this), trybAmount), "Bakiye veya onay (Approve) yetersiz");

        uint256 totalFee = (trybAmount * 3) / 1000;
        uint256 teamFee = (totalFee * 5) / 100;
        uint256 stakingFee = (totalFee * 35) / 100;
        uint256 lpFee = totalFee - teamFee - stakingFee; 
        
        require(trybToken.transfer(teamWallet, teamFee), "Ekip payi transfer hatasi");
        require(trybToken.transfer(stakingWallet, stakingFee), "Temettu transfer hatasi");
        emit FeeDistributed(teamFee, stakingFee, lpFee);

        uint256 netTryb = trybAmount - totalFee;
        uint256 assetAmountToGive = (netTryb * 10**18) / currentPrice;

        IERC20 targetAsset = assets[assetName].tokenContract;
        require(targetAsset.balanceOf(address(this)) >= assetAmountToGive, "Havuzda yeterli varlik kalmadi");
        require(targetAsset.transfer(msg.sender, assetAmountToGive), "Varlik gonderilemedi");

        emit Trade(msg.sender, assetName, trybAmount, assetAmountToGive);
    }
}
