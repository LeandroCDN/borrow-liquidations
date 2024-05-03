const readline = require('readline');
const checkTokens = require('./check-Tokens');
const formatList = require('./formatList');

// Función para mostrar las opciones al usuario
function mostrarMenu() {
    console.log('Selecciona una opción:');
    console.log('1. Ejecutar checkTokens');
    console.log('2. Ejecutar generar listas');
    // Agrega más opciones según tus necesidades
    console.log('0. Salir');
}

// Función para ejecutar el script seleccionado por el usuario
async function ejecutarOpcion(opcion, rl) {
    let input;
    switch(opcion) {
        case '1':
            // Aquí puedes pedir los parámetros necesarios para el script
            const protocol = await solicitarInput("Ingrese protocolo a analizar: ",  rl);
            input = await solicitarInput("Ingrese la blockchain a nalizar: ",  rl);
            await checkTokens(protocol,input);
            console.log("check tokens finalizado");
            break;
        case '2':
            input = await solicitarInput("Ingrese el nombre del folder: ",  rl);
            await formatList(input);
            break;
        // Agrega más casos para más scripts
        case '0':
            console.log('Saliendo del gestor de scripts.');
            process.exit();
        default:
            console.log('Opción no válida.');
    }
}

// Función principal para iniciar el gestor de scripts
async function iniciarGestor() {
    mostrarMenu();
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

    rl.question('Seleccione una opción: ', async (opcion) => {
        await ejecutarOpcion(opcion, rl);
        rl.close();
       // iniciarGestor(); // Vuelve a mostrar el menú después de ejecutar la opción
    });
}

// Iniciar el gestor de scripts
iniciarGestor();


async function solicitarInput(pregunta, rl) {
    try {
        return new Promise((resolve) => {
            rl.question(pregunta, (respuesta) => {
                resolve(respuesta);
            });
        });
    } catch (error) {
        console.error("Error al crear la interfaz readline:", error);
        throw error; 
    }
}
