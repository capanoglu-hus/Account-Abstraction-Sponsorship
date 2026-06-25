## Foundry

## Sepolia'da deploy edilmiş contract adresler
Resmi sepoliaEntryPoint = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;
SimpleAccountFactory = 0x8B15cA3e809aFae4039aF05F6D7Eb117e056C5bE;
Paymaster = 0xB12C53F7Ab00897Cb8990afbEFb239A418aBea4d;
testToken = 0x759f62A65f5A2dEb8Afe344504200156FfAA6528;

## Transaction işlemleri Etherscan link'leri ile verification
1. A cüzdanı oluştur -->        [0x24b6d124afc2724fb0cae66313290d911ffb50c770541a7cd10c72331dfd6199] (https://sepolia.etherscan.io/tx/0x24b6d124afc2724fb0cae66313290d911ffb50c770541a7cd10c72331dfd6199)
2. A cüzdanı adress --> 
   [0xee3E49ef57c871036B8Aa19B6576429ae3EA1B44]
   (https://sepolia.etherscan.io/address/0xee3e49ef57c871036b8aa19b6576429ae3ea1b44#tokentxns)
3. B cüzdanı -->
   [0xc1c515e4d4893AA981176f053478833D6045e321]
   (https://sepolia.etherscan.io/address/0xc1c515e4d4893aa981176f053478833d6045e321#tokentxns) 

4. TestToken mint etme -->
   [0x99e8945e12f41468e2aa70036153fcc92f056e04ea25e9b2b2d7830a287e10fe]
   (https://sepolia.etherscan.io/tx/0x99e8945e12f41468e2aa70036153fcc92f056e04ea25e9b2b2d7830a287e10fe)
5. Deposit To (EntryPoint'e Paymaster tarafından depozit verilmesi)
   (https://sepolia.etherscan.io/tx/0x58af14d2c19f416fa7136cdfffd1ed365c639208c12aa4844d117b5f5653b714) 
6. A'dan B'ye token transfer et (gas sponsor adresinden kesilsin) -->
   [0xb40278b407c07e6ab018b0f88f6663863c8d6f7bcc41cccef13c4446e068e944]
   (https://sepolia.etherscan.io/tx/0xb40278b407c07e6ab018b0f88f6663863c8d6f7bcc41cccef13c4446e068e944)
   (Gas ücreti Paymaster depozitosundan karşılandı, işlem Bundler tarafından ağa gönderildi)

## Setup Talimatları