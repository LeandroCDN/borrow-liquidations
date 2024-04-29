require("dotenv").config();
const createContract = require("./create-contract");
const sindicateABI = require("../../ABI/sindicate.json");
const fs = require("fs");
const path = require("path");
const { promisify } = require("util");

const readFileAsync = promisify(fs.readFile);

/* Check accounts for all addresses for a specific asset in a specific blockchain */
async function checkAccounts({
  sindicate,
  chainId,
  directionPath,
  blockchainName,
  tokenName,
}) {
  console.log("Iniciando el script Check-Accounts...");
  // const contractAddress = process.env.SEPOLIA_SINDICATE_V2_ADDRESS;
  // const rpc = process.env.SEPOLIA_ETH_RPC;
  // const ABI = sindicateABI.result;
  // const directionPath = "listOfHolders/direcciones.json";
  // const chainId = 99991;

  // const sindicate = await createContract({
  //   contractAddress,
  //   rpc,
  //   ABI,
  // });
  // Leer el archivo direcciones.json
  const direccionesPath = path.join(
    __dirname,
    `../../contracts/addresses/${directionPath}`
  );
  const direccionesData = await readFileAsync(direccionesPath, "utf8");
  const direcciones = JSON.parse(direccionesData);

  const lowFactorPath = path.join(__dirname, "../../LowFactor");
  if (!fs.existsSync(lowFactorPath)) {
    fs.mkdirSync(lowFactorPath);
  }
  const protocolPath = path.join(lowFactorPath, "/ZeroLend");
  if (!fs.existsSync(protocolPath)) {
    fs.mkdirSync(protocolPath);
  }

  // Crear la subcarpeta chainId dentro de LowFactor si no existe
  const chainFolderPath = path.join(protocolPath, blockchainName.toString());
  if (!fs.existsSync(chainFolderPath)) {
    fs.mkdirSync(chainFolderPath);
  }

  const resumeFilePath = path.join(chainFolderPath, "/resume");
  if (!fs.existsSync(resumeFilePath)) {
    fs.mkdirSync(resumeFilePath);
  }
  // Pasar cada vector de direcciones al método sindicate.check()
  const start = Date.now(); // Guarda el tiempo de inicio del proceso
  const length = direcciones.length;
  let status = "starting";
  let i = 0;
  let totalAddresses = 0;
  const minValue = 99999999;
  try {
    status = "Reading";
    for (const addressGroup of direcciones) {
      // const vectorDeTest = ["0x467941883c3062d1f04178f75e700a21f5a1aa90", "0x2f2920da1407b134cadd7207e21579ec20bb6a85", "0x97da64fdc901c64ce0588d61091085e180791519", "0x3b4977f2c6e90bc6bc4011b8443c578dd672ff44", "0x9b61542f076b8ae611650cc4eb932e60315f6a0f", "0x98a0ea5cba5ffb08bbc177880914ffafd390afa0", "0x9114361e38315a7f189158fb892e184bfd25a4d0", "0x00b9228eb19a13c6a943b350916dd2aa7f182c21", "0x875cbee17c35e8ce1f1919dd508de63e833d22c0", "0x046e2d2d1dde81f6a1d2d8f2bb8fb24a592371db"]
      const listOfLowHealtFactor = await sindicate.checkMinTotalCollateralBase(addressGroup, minValue);
      i++;

      // Buscar la posición de la primera dirección '0x0000000000000000000000000000000000000000'
      const indexOfZeroAddress = listOfLowHealtFactor.findIndex(
        ([address]) => address === "0x0000000000000000000000000000000000000000"
      );
      // Cortar el vector desde la primera posición hasta indexOfZeroAddress
      const trimmedResult = listOfLowHealtFactor.slice(
        0,
        indexOfZeroAddress 
      );
      const formattedResult = trimmedResult.map(([address, value]) => [
        address,
        value.toString(),
      ]);
      
      console.log(
        `[${blockchainName}-${tokenName}] Progress:[${i}/${length}] ResultLength: ${formattedResult.length}`
      );
      if(formattedResult.length > 0){
        totalAddresses+=formattedResult.length;
        // Escribir el archivo lowFactorAddresses.json con el contenido de trimmedResult
        const lowFactorFilePath = path.join(chainFolderPath, tokenName+".json");
        
        fs.writeFileSync(
          lowFactorFilePath,
          JSON.stringify(formattedResult, null, 2),
          { flag: "a" }
        );
      }
    }
    status = "Writed";
  } catch (error) {
    status = `Error: ${error}`;
    console.log("error: ", error);
  }
  const end = Date.now();
  const date = new Date(end);
  const formattedDate = `${date.getDate()}/${date.getMonth() + 1}/${date.getFullYear()} ${date.getHours()}:${date.getMinutes()}:${date.getSeconds()}`;
  
  const totalTimeInSeconds = (end - start) / 1000;
  // Crear el archivo resume.json
  const resumeData = {
    direcciones: totalAddresses,
    time: totalTimeInSeconds,
    lastRead: i,
    status: status,
    token: tokenName,
    blockchain: blockchainName,
    totalCollateralBase: minValue,
    time:formattedDate
  };

  const resumePath = path.join(resumeFilePath, `resume-${tokenName}.json`);
  fs.writeFileSync(resumePath, JSON.stringify(resumeData, null, 2),{ flag: "a" });
  console.log("Finish in:", totalTimeInSeconds, "seconds");
}

if (require.main === module) {
  checkAccounts();
}

// Exporta la función checkAccounts para poder ser utilizada desde otros módulos si es necesario
module.exports = checkAccounts;
