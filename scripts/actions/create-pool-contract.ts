import POOL_ABI from "@/../ABI/pool.json"
import { ethers } from 'ethers';

export default async function createPoolContract() {
    const contractAddress = process.env.NEXT_PUBLIC_AAVE_POOL_POLYGON;
    const infuraUrl = process.env.POLYGON_INFURA;
    const provider = new ethers.JsonRpcProvider(infuraUrl);

    try {
      const abiArray = JSON.parse(POOL_ABI.result);
      // Crear una instancia del contrato utilizando el ABI y la dirección del contrato
      if (!contractAddress) {
        throw new Error("La dirección del contrato no está definida en el archivo .env");
      }
      const contract = new ethers.Contract(contractAddress, abiArray, provider);
      return contract; // Devuelve la instancia del contrato
    } catch (error) {
      console.error('Error al crear la instancia del contrato:', error);
      throw error; // Propaga el error hacia arriba
    }
  }