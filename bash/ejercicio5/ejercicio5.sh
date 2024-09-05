#!/bin/bash

# Verifica si se consulta la ayuda.
if [[ $1 == "-h" || $1 == "--help" ]]; then
    echo "Uso: $0 [-p|--people <persona>] [-f|--film <película>]"
    echo "Opciones:"
    echo "  -p, --people   Nombre de la persona"
    echo "  -f, --film     Título de la película"
    echo "  -h, --help     Muestra esta ayuda"
    exit 0
fi

# Verifica la cantidad de parámetros.
if [[ $# -ne 2 && $# -ne 4 ]]; then
    echo "Error de sintaxis: Utilice $0 -h o --help para obtener ayuda."
    exit 1
fi

people=""
film=""

# Itera sobre los parámetros para asignar valores.
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--people)
            people="$2"
            shift 2
            ;;
        -f|--film)
            film="$2"
            shift 2
            ;;
        *)
            echo "Error de sintaxis: Parámetro desconocido $1"
            exit 1
            ;;
    esac
done

url_people="https://www.swapi.tech/api/people"
url_film="https://www.swapi.tech/api/film/"

# Verifica que los parámetros people y film estan vacios
if [[ -z "$people" && -z "$film" ]]; then
    echo "Error de sintaxis: Utilice $0 -h o --help para obtener ayuda."
    exit 1
fi

# Verifica si el parametro people no este vacio y procesa las consultas
if [[ -n $people ]]; then
    ids=($(echo "$people" | cut -d',' --output-delimiter=' ' -f1-))
    
    for id in "${ids[@]}"; do
        wget -qO- "$url_people/$id" | jq "{Id:.result.uid, Name:.result.properties.name, Gender:.result.properties.gender}" 
    done
fi

# Verifica si el parametro film no este vacio y procesa las consultas
if [[ -n  $film ]]; then
    echo "Pelicula"
fi


