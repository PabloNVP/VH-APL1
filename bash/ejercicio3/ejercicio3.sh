#!/bin/bash

###                 INTEGRANTES                     ###
###     Vazquez Petracca, Pablo N.  - CONFIDENCE    ### 
###     Rodriguez, Pablo            - CONFIDENCE    ### 
###     Collazo, Ignacio Lahuel     - CONFIDENCE    ### 
###     Pozzato, Alejo Martin       - CONFIDENCE    ### 
###     Rodriguez, Emanual          - CONFIDENCE    ###

# Verifica si se consulta la ayuda.
if [[ $1 == "-h" || $1 == "--help" ]]; then
    echo "Uso: $0 [-d|--directorio <DIRECTORIO>]"
    echo "Lista los archivos duplicados y en qué directorio fueron encontrados."
    echo "Opciones:"
    echo "  -d, --directorio   Ruta del directorio a analizar."
    echo "  -h, --help         Muestra la ayuda"
    exit 0
fi

# Verifica la cantidad de parámetros.
if [[ $# -ne 2 ]]; then
    echo "Error de sintaxis: Utilice $0 -h o --help para obtener ayuda."
    exit 1
fi

path=""

# Verifica si es el parametro correcto.
if [[ $1 == "-d" || $1 == "--directorio" ]]; then
    
    #Verifica si es un directorio.
    if [[ -d "$2" ]]; then
        path="$2"
    else
        echo "El parametro "$2" no es un directorio."
        exit 1
    fi
else
    echo "Error de sintaxis: Utilice $0 -h o --help para obtener ayuda."
    exit 1
fi

ls -LlR "$path" | awk '
BEGIN{
    printed=0
}
/:$/ {
    path = substr($0, 1, length($0) - 1)
}
/^-/ {
    size = $5
    name = ""
    for (i = 9; i <= NF; i++) {
        name = (name == "" ? $i : name " " $i)
    }
    key = name " " size
    files[key] = files[key] ? files[key] "|" path : path
}
END {
    for (key in files) {
        split(files[key], dirs, "|")
        if (length(dirs) > 1) {
            split(key, file, " ")
            for(i=0; i<length(file)-1; i++){
                nam = i==0 ? file[i] : nam " " file[i]
            }
            print "Archivo:", nam
            for (i in dirs) {
                print dirs[i]
            }
            print ""
            printed=1
        }
    }
    if(printed==0){
        print "No se encontraron archivos duplicados en el directorio."
    }
}'

