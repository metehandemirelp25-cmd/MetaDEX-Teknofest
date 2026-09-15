// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MetaDEX is Ownable {
    IERC20 public tokenTRYB;
    IERC20 public tokenGLD;
    
    // Senin Tanımladığın Profesyonel Cüzdan Mimarisi
    address public teamWallet = 0x65Fd7d8BaC5D15c0d8a848c7F224AFed8a6EcB8e;
    address public loyaltyWallet = 0x3F5a4209BF3ef91862854D6dcF8aF3c61Ffbe0AE;
    address public lpWallet = 0xE41540D41DD6b541556fbC8a8e660EdD9678aD87;

    // Sabit Kur (1 Gram Altın = 2500 TL)
    uint256 public goldPriceInTRYB = 2500; 

    // Havuz kurulurken artık sadece TRYB ve GLD adreslerini alıyoruz (META'yı kaldırdık)
    constructor(address _tryb, address _gld) Ownable(msg.sender) {
        tokenTRYB = IERC20(_tryb);
        tokenGLD = IERC20(_gld);
    }

    // Kullanıcının tTRYB verip tGLD aldığı profesyonel fonksiyon
    function buyGold(uint256 trybAmount) public {
        require(trybAmount > 0, "Sifirdan buyuk bir miktar girmelisiniz");
        
        // 1. Sektör standardı toplam %0.3 Komisyonu Hesapla (trybAmount * 3 / 1000)
        uint256 totalFee = (trybAmount * 3) / 1000;
        
        // 2. Senin Mükemmel Dağılım Kodun
        uint256 teamFee = (totalFee * 5) / 100;       // %5 Ekip Maaşı
        uint256 loyaltyFee = (totalFee * 35) / 100;   // %35 Temettü / Staking
        uint256 lpFee = totalFee - teamFee - loyaltyFee; // %60 Havuz (LP) Payı

        // 3. Komisyon kesildikten sonra altin almak icin kalan NET TRYB
        uint256 netTrybForGold = trybAmount - totalFee;
        
        // 4. Verilecek Altın Miktarını Hesapla
        uint256 goldAmount = netTrybForGold / goldPriceInTRYB;

        // Havuzda altın kalmadıysa işlemi durdur (Güvenlik)
        require(tokenGLD.balanceOf(address(this)) >= goldAmount, "Havuzda yeterli altin yok");

        // 5. Müşteriden Toplam TRYB'yi Tahsil Et
        tokenTRYB.transferFrom(msg.sender, address(this), trybAmount);

        // 6. Komisyonları İlgili Cüzdanlara Tıkır Tıkır Dağıt
        tokenTRYB.transfer(teamWallet, teamFee);
        tokenTRYB.transfer(loyaltyWallet, loyaltyFee);
        tokenTRYB.transfer(lpWallet, lpFee);

        // 7. Müşteriye Altınını (tGLD) Teslim Et
        tokenGLD.transfer(msg.sender, goldAmount);
    }
}
