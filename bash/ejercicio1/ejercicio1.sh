#!/bin/bash

###                 INTEGRANTES                     ###
###     Vazquez Petracca, Pablo N.  - CONFIDENCE    ###
###     Rodriguez, Pablo            - CONFIDENCE    ###
###     Collazo, Ignacio Lahuel     - CONFIDENCE    ###
###     Pozzato, Alejo Martin       - CONFIDENCE    ###

function ayuda(){
        echo "Uso: $0 [opciones]"
        echo "Opciones:"
        echo "  -d, --directorio        Ruta del directorio que contiene los arhivos csv a procesar(obligatorio)"
        echo "  -a, --archivo           Ruta del archivo dónde se guardaran los resultados(no puede usarse con --pantalla)"
        echo "  -p, --pantalla        Muestra salida en pantalla de los resultados(no puede usarse con --archivo)"
        echo "  -h, --help            Muestra ayuda"
}

function manejoParametros(){
        directorio=""
        archivo=""
        pantalla=0

        opciones=$(getopt -o d:a:ph --l directorio:,archivo:,pantalla,help -- "$@" 2>/dev/null)

        if [ "$?" -ne 0 ]
        then
                echo "Error: Opciones incorrectas o incompletas"
                exit 1
        fi

        eval set -- "$opciones"
        #Proceso opciones

        while true
        do
                case "$1" in
                        -d | --directorio)
                                directorio="$2"
                                shift 2
                                ;;
                        -a | --archivo)
                                archivo="$2"
                                shift 2
                                ;;
                        -h | --help)
                                ayuda
                                exit 0
                                ;;
                        -p | --pantalla)
                                pantalla=1
                                shift
                                ;;
                        --)
                                shift
                                break
                                ;;
                        *)
                                echo "Error"
                                exit 1
                                ;;
                esac
        done

}
function validacionParametros(){
        #Compruebo si directorio no esta vacio y si existe un metodo de salida
        if [ -z "$directorio" ];
        then
                echo "Error: El parametro --directorio es obligatorio"
                exit 1
        fi

        if [ ! -d "$directorio" ];
        then
                echo "Error, El directorio '$directorio' no existe"
                exit 1
        fi

        if [ -z "$archivo" ] && [ "$pantalla" -eq 0 ];
        then
                echo "Error, debe elegir una salida: -p para informar por pantalla o -a para que sea en un archivo"
                exit 1
        elif [ -n "$archivo" ] && [ "$pantalla" -eq 1 ];
        then
                echo "Error: Las opciones --archivo y --pantalla no pueden usarse al mismo tiempo"
                exit 1
        fi

        if [ -n "$archivo" ];
        then
                #Me quedo con la ruta del archivo
                rutaArchivo=$(dirname "$archivo" 2>/dev/null)
                if [ ! -d "$rutaArchivo" ];
                then
                        echo "Error, La ruta de directorios para el archivo no existe"
                        exit 1
                fi
		
		nombreArchivo=$(basename "$archivo")
    		if [ -z "$nombreArchivo" ]; then
        		echo "Error: El parámetro no contiene un nombre de archivo"
        		exit 1
    		fi
        fi
}

function scriptAWK(){
 cat << 'EOF' #Creo un heredoc con el codigo awk
        BEGIN {
                FS = ",";
                cuatro = 1;
                tres = 1;
                primero = 1; #Variable auxiliar para manejar el JSON (identifica si es o no el primer objeto)
                getline linea < numerosGanadores; #Obtengo los números ganadores del archivo pasado como parámetro
                split(linea, ganadores, ",");

		#Comienzo a escribir el json
                printf ("{\n");
                printf ("\t\"5_aciertos\": [\n");

        }
        {
                if (FILENAME == numerosGanadores) { #Si el archivo actual es el de numerosGanadores, continua con el siguiente
                         next;
                }
		
		#Elimino el carácter '\r' si existe (para archivos creados en Windows)
		gsub(/\r$/, "")
		
		#Valido que los archivos tengan 6 campos
		if (NF != 6){
                        next; 
                }

                #Valido que cada campo contenga un número entero
                for (i = 1; i <= NF; i++) {
                        if ($i !~ /^[[:digit:]]+$/){
                                next; 
                        }
                }

		
                #CUENTO LOS ACIERTOS
                num_aciertos = 0;
                for (i=2; i<=6; i++) {
                        for (j=1; j<=length(ganadores); j++) {
                                if ($i == ganadores[j]) {
                                        num_aciertos++;
                                }
                        }
                }

                #CLASIFICO LOS ACIERTOS
                if (num_aciertos == 5) {
                        #Proceso la agencia a la que pertenece la jugada
                        split(FILENAME, directorios, "/");
                        archivo = directorios[length(directorios)]; #Me quedo con el arch.csv
                        split(archivo, nroAgencia, "."); #Me quedo con el número de agencia
                        agencia = nroAgencia[1];

                        if (primero == 0) { #Verifico si no es el primero agrego
                                printf (",\n");
                        }
                        printf ("\t\t{\n");
                        printf ("\t\t\t\"agencia\": \"%s\",\n", agencia);
                        printf ("\t\t\t\"jugada\": \"%s\"\n", $1);
                        printf ("\t\t}");

                        primero = 0;
                } else if (num_aciertos == 4) {
                        cuatroAciertos[cuatro] = $1;

                        split(FILENAME, directorios, "/");
                        archivo = directorios[length(directorios)]; #Me quedo con el arch.csv
                        split(archivo, nroAgencia, "."); #Me quedo con el número de agencia
                        vectorAgenciasCuatro[cuatro] = nroAgencia[1];

                        cuatro++;
                } else if (num_aciertos == 3) {
                        tresAciertos[tres] = $1;

                        split(FILENAME, directorios, "/");
                        archivo = directorios[length(directorios)];
                        split(archivo, nroAgencia, ".");
                        vectorAgenciasTres[tres] = nroAgencia[1];

                        tres++;
                                        }
        }
        END {
                #TERMINO DE ESCRIBIR EL JSON
                if (primero != 1) { #Evito hacer un \n de más si 5_aciertos está vacío
                        printf ("\n");
                }

                primero = 1; #Reinicio primero para utilizarlo más tarde

                printf ("\t],\n");
                printf ("\t\"4_aciertos\": [\n");

                for (i = 1; i < cuatro; i++) {
                        if (primero == 0) { #Verifico si no es el primero que agrego
                                printf (",\n");
                        }
                        printf ("\t\t{\n");
                        printf ("\t\t\t\"agencia\": \"%s\",\n", vectorAgenciasCuatro[i]);
                        printf ("\t\t\t\"jugada\": \"%s\"\n", cuatroAciertos[i]);
                        printf ("\t\t}");

                        primero = 0;
                }

                if (primero != 1) {
                        printf ("\n"); #Evito hacer un \n de más si 4_aciertos está vacío
                }

                primero = 1;
                printf ("\t],\n");
                printf ("\t\"3_aciertos\": [\n");
                for (i = 1; i < tres; i++) {
                        if (primero == 0) {
                                printf (",\n");
                        }
                        printf ("\t\t{\n");
                        printf ("\t\t\t\"agencia\": \"%s\",\n", vectorAgenciasTres[i]);
                        printf ("\t\t\t\"jugada\": \"%s\"\n", tresAciertos[i]);
                        printf ("\t\t}");

                        primero = 0;
                }

                if (primero != 1) {
                        printf ("\n");
                }
                printf ("\t]\n");
                printf ("}\n");
        }
EOF
}

function identificarNumerosGanadores {
        archivoGanadores=""

        for archivo in "$directorio"/*.csv; do
                #Obtengo la cantidad de campos de la primera línea del archivo
                campos=$(awk -F, 'NR==1 {print NF}' "$archivo" 2>/dev/null)

                if [ $? -ne 0 ]; then
                        echo "Error: Falló la ejecución de AWK para el archivo $archivo, revise que el archivo no tenga errores"
                        exit 1
                fi
                
                #Comparo con la cantidad de campos actual y actualizo si corresponde
                if [ $campos -eq 5 ]; then
                        archivoGanadores=$archivo
			break
                fi
        done
        echo "$archivoGanadores"
}


function procesamiento(){
        #Identifico el archivo con los números ganadores
        numerosGanadores=$(identificarNumerosGanadores)

        #Verifico que exista el archivo
        if [ -z "$numerosGanadores" ]; then
                echo "Error: No se encontró el archivo de números ganadores"
                exit 1
        fi

        #Creo un archivo temporal para ejecutar el codigo awk
        awkScript="/tmp/awkScript.awk"

        scriptAWK > "$awkScript"

        if [ "$pantalla" -eq 1 ]
        then
		awk -v numerosGanadores="$numerosGanadores" -f "$awkScript" "$directorio"/*.csv 2>/dev/null
                if [ $? -ne 0 ]; then
			echo "Error: Verifique los archivos que contiene $directorio"
			exit 1
               	fi
        else
                awk -v numerosGanadores="$numerosGanadores" -f "$awkScript" "$directorio"/*.csv >> "$archivo"
                if [ $? -ne 0 ]; then
                        echo "Error: Verifique el archivo de salida o los archivos que contiene $directorio"
                        exit 1
               	fi
	fi

        #Elimino el archivo temporal
        rm "$awkScript"
}

#-----------------------------------------------INICIO PROGRAMA---------------------------------------------------

manejoParametros "$@" #Envio las opciones que se seleccionaron a la funcion
validacionParametros
procesamiento

if [ -n "$archivo" ];
then
        echo "Se ejecutó correctamente"
fi
