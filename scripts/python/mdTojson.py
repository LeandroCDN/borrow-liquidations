import json

# Leer el archivo .md y obtener las direcciones
with open("variableDebtPolDAI.txt", "r") as file:
    addresses = [line.strip() for line in file if line.strip()]

# Filtrar las direcciones vacías
addresses = [address for address in addresses if address]

# Convertir las direcciones en cadenas con comillas
address_strings = ["" + address + "" for address in addresses]

# Dividir las direcciones en grupos de tamaño deseado
group_size = 200  # Puedes ajustar este valor según tus necesidades
address_groups = [
    address_strings[i : i + group_size]
    for i in range(0, len(address_strings), group_size)
]

# Escribir los resultados en un archivo JSON
with open("variableDebtPolDAI.json", "w") as outfile:
    json.dump(address_groups, outfile)
