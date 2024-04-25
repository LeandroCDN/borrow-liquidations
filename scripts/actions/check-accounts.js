require('dotenv').config(); 
const createContract = require("./create-contract");
const sindicateABI = require("../../ABI/sindicate.json");
const fs = require("fs");
const path = require("path");
const { promisify } = require("util");

const readFileAsync = promisify(fs.readFile);

/* Check accounts for all addresses for a specific asset in a specific blockchain */
async function checkAccounts() {
  console.log("Iniciando el script...");
  const contractAddress = process.env.SEPOLIA_SINDICATE_ADDRESS;
  const url = process.env.SEPOLIA_ETH_RPC;
  const ABI = sindicateABI.result;
  const directionPath = "listOfHolders/direcciones.json";
  const chainId = 99991;

  const sindicate = await createContract({
    contractAddress,
    url,
    ABI,
  });
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

  // Crear la subcarpeta chainId dentro de LowFactor si no existe
  const chainFolderPath = path.join(lowFactorPath, chainId.toString());
  if (!fs.existsSync(chainFolderPath)) {
    fs.mkdirSync(chainFolderPath);
  }
  // Pasar cada vector de direcciones al método sindicate.check()
  const start = Date.now(); // Guarda el tiempo de inicio del proceso
  const length = direcciones.length;
  let status = 'starting'
  let i = 0;
  try {
    status = 'Reading'
    for (const addressGroup of direcciones) {    
      const listOfLowHealtFactor = await sindicate.check(addressGroup);
      i++;
      console.log(`listOfLowHealtFactor:[${i}/${length}] `, listOfLowHealtFactor);
      // Escribir el archivo lowFactorAddresses.json con el contenido de listOfLowHealtFactor
      const lowFactorFilePath = path.join(chainFolderPath, "lowFactorAddresses.json");
      fs.writeFileSync(lowFactorFilePath, JSON.stringify(listOfLowHealtFactor, null, 2), { flag: 'a' });
    }
    status = 'Writed'
  } catch (error) {
    status = `Error: ${error}`;
    console.log('error: ', error);
  }
  const end = Date.now(); // Guarda el tiempo de finalización del proceso
  const totalTimeInSeconds = (end - start) / 1000; 
   // Crear el archivo resume.json
   const resumeData = {
    direcciones: length,
    time: totalTimeInSeconds,
    lastRead: i,
    status: status
  };
  const resumeFilePath = path.join(chainFolderPath, "resume.json");
  fs.writeFileSync(resumeFilePath, JSON.stringify(resumeData, null, 2));
  console.log("Finish in:", totalTimeInSeconds, "seconds");
}

if (require.main === module) {
  checkAccounts();
}

// Exporta la función checkAccounts para poder ser utilizada desde otros módulos si es necesario
module.exports = checkAccounts;

/**
 * 
 * require('dotenv').config(); 
const createContract = require("./create-contract");
const sindicateABI = require("../../ABI/sindicate.json");
const fs = require("fs");
const path = require("path");
const { promisify } = require("util");

const readFileAsync = promisify(fs.readFile);

 Check accounts for all addresses for a specific asset in a specific blockchain
async function checkAccounts() {
  console.log("Iniciando el script...");
  const contractAddress = process.env.SEPOLIA_SINDICATE_ADDRESS;
  const url = process.env.SEPOLIA_ETH_RPC;
  const ABI = sindicateABI.result;
  const path = "listOfHolders/direcciones2.json";
  const chainId = 99991;

  const sindicate = await createContract({
    contractAddress,
    url,
    ABI,
  });
  // Leer el archivo direcciones.json
  const direccionesPath = path.join(
    __dirname,
    `../../contracts/addresses/${path}`
  );
  const direccionesData = await readFileAsync(direccionesPath, "utf8");
  const direcciones = JSON.parse(direccionesData);
  // Pasar cada vector de direcciones al método sindicate.check()
  const start = Date.now(); // Guarda el tiempo de inicio del proceso
  const lenght = direcciones.length;
  let status = 'starting'
  let i = 0;
  try {
    status = 'Reading'
    for (const addressGroup of direcciones) {    
      const listOfLowHealtFactor = await sindicate.check(addressGroup);
      i++;
      console.log(`listOfLowHealtFactor:[${i}/${lenght}] `, listOfLowHealtFactor);
      const lowFactorPath = path.join(__dirname, "../../LowFactor");
      if (!fs.existsSync(lowFactorPath)) {
        fs.mkdirSync(lowFactorPath);
      }

      // Crear la subcarpeta chainId dentro de LowFactor si no existe
      const chainFolderPath = path.join(lowFactorPath, chainId.toString());
      if (!fs.existsSync(chainFolderPath)) {
        fs.mkdirSync(chainFolderPath);
      }
      
      // Escribir el archivo lowFactorAddresses.json con el contenido de listOfLowHealtFactor
      const lowFactorFilePath = path.join(chainFolderPath, "lowFactorAddresses.json");
      fs.writeFileSync(lowFactorFilePath, JSON.stringify(listOfLowHealtFactor, null, 2));
      
    }
    status = 'Writed'
  } catch (error) {
    status = `Error: ${error}`;
    console.log('error: ', error);
  }
   // Crear el archivo resume.json
   const resumeData = {
    direcciones: length,
    lastRead: i,
    status: status
  };
  const resumeFilePath = path.join(chainFolderPath, "resume.json");
  fs.writeFileSync(resumeFilePath, JSON.stringify(resumeData, null, 2));
  const end = Date.now(); // Guarda el tiempo de finalización del proceso
  const totalTimeInSeconds = (end - start) / 1000; 
  console.log("Finish in:", totalTimeInSeconds, "seconds");
}

if (require.main === module) {
  checkAccounts();
}
 */