const checkAccounts = require("./check-accounts");
const createContract = require("./create-contract");
const continentalABI = require("../../ABI/continental.json");
const addressIndex = require("../addreseses/addressIndex.json");
const c = require("../utils/consoleColors");

async function checkTokens(protocolToCheck = "all", blockchainToCheck = "all") {
  try {
    const ABI = continentalABI.result;
    const protocols =
      protocolToCheck === "all"
        ? Object.keys(addressIndex.Protocols)
        : [protocolToCheck];

    for (const protocol of protocols) {
      if (!(protocol in addressIndex.Protocols)) {
        console.error(`Protocolo '${protocol}' no encontrado en addressIndex`);
        continue;
      }

      const protocolData = addressIndex.Protocols[protocol];
      const blockchains =
        blockchainToCheck === "all"
          ? Object.keys(protocolData.blockchains)
          : [blockchainToCheck];

      for (const blockchainName of blockchains) {
        const blockchain = protocolData.blockchains[blockchainName];
        const { contractAddress, tokens, chainId, rpc } = blockchain;
        const sindicate = await createContract({
          contractAddress,
          rpc,
          ABI,
        });

        for (const [tokenName, directionPath] of Object.entries(tokens)) {
          // Llamar a checkAccounts con diferentes valores de floor y roof
          await checkAccounts({
            sindicate,
            chainId,
            directionPath,
            blockchainName,
            tokenName,
            floor: "650000000000000000",
            roof: "950000000000000000",
          });

          await checkAccounts({
            sindicate,
            chainId,
            directionPath,
            blockchainName,
            tokenName,
            floor: "950000000000000000",
            roof: "1000000000000000000",
          });

          await checkAccounts({
            sindicate,
            chainId,
            directionPath,
            blockchainName,
            tokenName,
            floor: "1000000000000000000",
            roof: "1010000000000000000",
          });
        }
      }
    }

    console.log(
      `${c.FG_YELLOW}Procesamiento de tokens completado para el protocolo: ${protocolToCheck}, blockchain: ${blockchainToCheck}${c.RESET}`
    );
  } catch (error) {
    console.error("Error al verificar tokens:", error);
  }
}

if (require.main === module) {
  // Si se ejecuta directamente, se usa "undefined" como argumento para analizar todas las blockchains y protocolos
  checkTokens();
}

module.exports = checkTokens;
