const checkAccounts = require("./check-accounts");
const createContract = require("./create-contract");
const sindicateABI = require("../../ABI/sindicate.json");
const addressIndex = require("../addreseses/addressIndex.json");

async function checkTokens() {
  
  try {
    const ABI = sindicateABI.result;
    const zeroLend = addressIndex.Aave;
    for (const blockchainName in zeroLend.blockchains) {
      const blockchain = zeroLend.blockchains[blockchainName];
      const { contractAddress, tokens, chainId, rpc } = blockchain;

      console.log(rpc);
      const sindicate = await createContract({
        contractAddress,
        rpc,
        ABI,
      });
      console.log("start second for:");
      for (const [tokenName, directionPath] of Object.entries(tokens)) {
        try {
          // Cargar directamente el archivo JSON
          //   const fullPath = require.resolve(path.join(__dirname, directionPath));
          //   const direcciones = require(fullPath);

          // Ejecutar la función checkAccounts para cada par de contrato/dirección
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
  } catch (error) {
    console.error("Error al verificar tokens:", error);
  }
}

if (require.main === module) {
  checkTokens();
}

module.exports = checkTokens;
