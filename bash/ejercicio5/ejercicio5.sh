#!/bin/bash

###                 INTEGRANTES                     ###
###     Vazquez Petracca, Pablo N.  - CONFIDENCE    ### 
###     Rodriguez, Pablo            - CONFIDENCE    ### 
###     Collazo, Ignacio Lahuel     - CONFIDENCE    ### 
###     Pozzato, Alejo Martin       - CONFIDENCE    ### 
###     Rodriguez, Emanual          - CONFIDENCE    ###

# Verifica si se consulta la ayuda.
if [[ $1 == "-h" || $1 == "--help" ]]; then
    echo "Uso: $0 [-p|--people <ID/s Personaje/s>] [-f|--film <ID/s Peliculas>]"
    echo "Consulta información relacionada al mundo de Star Wars"
    echo "Opciones:"
    echo "  -p, --people   ID/s de los Personaje/s"
    echo "  -f, --film     ID/s de la/s Pelicula/s"
    echo "  -h, --help     Muestra la ayuda"
    echo "  -c, --clear    Limpia la memoria cache"
    exit 0
fi

#Path de la Memoria Cache
path_people="$HOME/people.json"
path_film="$HOME/film.json"

# Verifica si ingresa la limpieza.
if [[ $1 == "-c" || $1 == "--clear" ]]; then
    echo "Se esta limpiando la memoria cache..."

    if [[ -f "$path_people" ]]; then
        rm -f "$path_people"
        echo "  [*] Limpieza de Personajes completa."
    fi

    if [[ -f "$path_film" ]]; then
        rm -f "$path_film"
        echo "  [*] Limpieza de Peliculas completa."
    fi
    echo "Se ha completado la limpieza de la memoria cache."
    exit 0
fi

# Verifica la cantidad de parámetros.
if [[ $# -ne 2 && $# -ne 4 ]]; then
    echo "Error de sintaxis: Utilice $0 -h o --help para obtener ayuda."
    exit 1
fi

#ID/s ingresadas por parametro
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

# Verifica que los parámetros people y film estan vacios
if [[ -z "$people" && -z "$film" ]]; then
    echo "Error de sintaxis: Utilice $0 -h o --help para obtener ayuda."
    exit 1
fi

# Consulta las Peliculas o Personajes dependiendo los parametros
function query(){
    # Verifica si el parametro no este vacio y procesa las consultas
    if [[ -n "$1" ]]; then
        ids=($(echo "$1" | cut -d',' --output-delimiter=' ' -f1-))
        begin=true #Flag para saber si es el inicio de la impresión

        for id in "${ids[@]}"; do

            if [[ ! -f "$2" ]]; then
                echo "[]" > "$2"
            fi

            result=$(jq ".[] | select(.Id == \"$id\")" "$2")

            if [[ -z "$result"  ]]; then
                result=$(wget -qO- "$3/$id")

                if [[ -z "$result"  ]]; then
                    det=$([[ "$4" == "Personaje" ]] && echo "ningún" || echo "ninguna")
                    echo -e "No existe "$det" "$4" con el id \"$id\" \n"
                    continue
                else
                    if [[ "$4" == "Personaje" ]]; then
                        result=$(echo "$result" | jq '.result | {Id: .uid, Name: .properties.name, Gender: .properties.gender, Height: .properties.height, Mass: .properties.mass, "Birth Year": .properties.birth_year}')
                    else
                        result=$(echo "$result" | jq '.result | {Id: .uid, Title: .properties.title, "Episode id": .properties.episode_id, "Release date": .properties.release_date,"Opening crawl": .properties.opening_crawl}')
                    fi
            
                    json=$(jq --argjson new "$result" '. + [$new]' "$2")
                    echo "$json" > "$2"
                fi
            fi

            #Formateo la respuesta según sea Personaje o Pelicula
            if [[ "$4" == "Personaje" ]]; then
                if $begin; then
                    echo "Personajes:"
                    begin=false
                fi
                echo $result | jq -r '. | "Id: \(.Id)\nName: \(.Name)\nGender: \(.Gender)\nHeight: \(.Height)\nMass: \(.Mass)\nBirth Year: \(.["Birth Year"])\n"'
            else
                if $begin; then 
                    echo "Peliculas:"
                    begin=false
                fi
                echo $result | jq -r '. | "Title: \(.Title)\nEpisode id: \(.["Episode id"])\nRelease date: \(.["Release date"])\nOpening crawl: \(.["Opening crawl"])\n"'
            fi
        done
    fi
}

#EndPoints de la API
url_people="https://www.swapi.tech/api/people"
url_film="https://www.swapi.tech/api/films"

#Consulta de Personajes
query "$people" "$path_people" "$url_people" "Personaje"

#Consulta de Peliculas
query "$film" "$path_film" "$url_film" "Pelicula"


