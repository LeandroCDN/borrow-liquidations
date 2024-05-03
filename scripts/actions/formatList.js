const fs = require("fs");
const path = require("path");

async function formatList(saveFolder) {
    const inputFolderPath = path.join(__dirname, `../csv/${saveFolder}/`);
    const outputFolderPath = path.join(__dirname, `../../Lists/${saveFolder}/`);

    const files = fs.readdirSync(inputFolderPath);    

    files.forEach((file) => {
        // Leer el contenido del archivo .csv
        const fileContent = fs.readFileSync(path.join(inputFolderPath, file), "utf8");
        const addresses = fileContent
            .split("\n")
            .map((line) => line.trim())
            .filter((line) => line);

        // Dividir las direcciones en grupos de tamaño deseado
        const groupSize = 500; // Puedes ajustar este valor según tus necesidades
        const addressGroups = [];
        for (let i = 0; i < addresses.length; i += groupSize) {
            addressGroups.push(addresses.slice(i, i + groupSize));
        }

        // Escribir los resultados en un archivo JSON
        const jsonData = JSON.stringify(addressGroups, null, 2);
        const outputFile = path.join(outputFolderPath, `${path.parse(file).name}.json`);
        fs.writeFileSync(outputFile, jsonData, "utf8");

        console.log(`Archivo JSON generado correctamente: ${outputFile}`);
    });

    console.log(`Procesamiento de archivos completado para la carpeta: ${saveFolder}`);

    
}

module.exports = formatList;