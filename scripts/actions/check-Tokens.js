const checkAccounts = require("./check-accounts");
const createContract = require("./create-contract");
const continentalABI = require("../../ABI/continental.json");
const addressIndex = require("../addreseses/addressIndex.json");

async function checkTokens(protocolToCheck = "all", blockchainToCheck = "all") { 
  try {
    const ABI = continentalABI.result;
    const protocols = protocolToCheck === "all" ? Object.keys(addressIndex) : [protocolToCheck];
    console.log("debug log, checkTokens: protocols:",protocols );
    console.log("debug log, checkTokens: protocolToCheck:",protocolToCheck );
    console.log("debug log, checkTokens: blockchainToCheck:",blockchainToCheck );
    for (const protocol of protocols) {
      const protocolData = addressIndex[protocol];
      const blockchains = blockchainToCheck === "all" ? Object.keys(protocolData.blockchains) : [blockchainToCheck];
      
      for (const blockchainName of blockchains) {
        const blockchain = protocolData.blockchains[blockchainName];
        const { contractAddress, tokens, chainId, rpc } = blockchain;
        const sindicate = await createContract({
          contractAddress,
          rpc,
          ABI,
        });
        
        for (const [tokenName, directionPath] of Object.entries(tokens)) {
          try {
            await checkAccounts({
              sindicate,
              chainId,
              directionPath,
              blockchainName,
              tokenName,
            });
          } catch (error) {
            console.error(`Error al cargar el archivo ${directionPath}:`, error);
          }
        }
      }
    }
    
    console.log(`Procesamiento de tokens completado para el protocolo: ${protocolToCheck}, blockchain: ${blockchainToCheck}`);
  } catch (error) {
    console.error("Error al verificar tokens:", error);
  }
}

if (require.main === module) {
  // Si se ejecuta directamente, se usa "undefined" como argumento para analizar todas las blockchains y protocolos
  checkTokens();
}

module.exports = checkTokens;

