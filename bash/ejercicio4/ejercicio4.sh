#!/bin/bash

    # +------------------------------------+
    # | Grupo |    Integrantes             |
    # -------------------------------------|
    # |       | Collazo, Ignacio           |
    # |  01   | Pozzato, Alejo             |
    # |       | Rodriguez, Emanuel         |
    # |       | Rodriguez, Pablo           |
    # |       | Vazquez Petracca, Pablo    |
    # +------------------------------------+

# Manejo de interrupcion por teclado (Ctrl+C)
function ctrl_c() {
    printf "\nScript interrumpido por el usuario. Saliendo...\n"
    exit 8  # Codigo de salida 8 para SIGINT
}

trap ctrl_c INT


function ayuda {
    printf "\n##############################################################################################################################################"

    printf "
    Uso: sh $0 [OPCIONES] [ARGUMENTOS]"

    printf "\n
    Opciones:
    -h, --help          Muestra ayuda en pantalla
    -d, --directorio    <directorio> - Ruta del directorio a monitorear. Obligatorio.
    -s, --salida        <salida> - Ruta destino de los archivos .tar.gz. Opcional.
    -k, --kill          <kill> - Parametro utilizado para indicar finalizacion del demonio. Opcional.
    
    +----- Los parametros '-s' y '-k' no pueden ser utilizados al mismo tiempo. -----+
    "

    printf "\n
    Prerequisitos:
    + El script utiliza la herramienta inotify-tools. Debe estar instalado previo a la ejecucion del script.
    "

    printf "\n
    Ejemplos:
    
    # Monitoreo del directorio 'archivos' y archivos comprimidos ubicados en 'backups'
    sh $0 -d '/home/user/bash/archivos' -s '/home/user/bash/backups'
    sh $0 --directorio '/home/user/bash/archivos' --salida '/home/user/bash/backups'
    sh $0 -d './archivos' -s './backups'

    # Parametros sin orden
    sh $0 -s '/home/user/bash/backups' -d '/home/user/bash/archivos'
    sh $0 --salida '/home/user/bash/backups' --directorio '/home/user/bash/archivos'
    sh $0 -s './backups' -d './archivos'

    # Finalizacion del demonio correspondiente al directorio enviado
    sh $0 -d '/home/user/bash/archivos' -k
    sh $0 --directorio '/home/user/bash/archivos' --kill
    sh $0 -d './archivos' -k

    # Seccion ayuda
    sh $0 -h
    sh $0 --help"

    printf "\n
    Tabla de codigos de error:
    +----------------------------------------------------------------------------------------+
    |  Codigo |                             Descripcion                                      |
    -----------------------------------------------------------------------------------------|
    |    01   | Parametros invalidos.                                                        |
    |    02   | Error parseando parametros.                                                  |
    |    03   | Falta(n) parametro(s) obligatorio(s).                                        |
    |    04   | No se pueden enviar los parametros --salida (-s) y --kill (-k) a la vez.     |
    |    05   | El directorio especificado a monitorear no existe.                           |
    |    06   | El directorio especificado de salida para backups no existe.                 |
    |    07   | Ya existe un demonio activo para el directorio especificado.                 |
    +----------------------------------------------------------------------------------------+
    "

    printf "\n##############################################################################################################################################\n\n"
}


function mostrar_titulos {
    printf "\n############### Ejercicio 4 ###############\n"

    if [ $flag_kill ]; then
        printf "+ Parametro kill recibido.\n\n"
    else
        printf " + Cantidad de parametros con valores: $cantidad_opciones\n"
        printf " + Parametros:\n"
        printf "\t1- Directorio a monitorear: '$directorio'\n"
        printf "\t2- Directorio destino de los backups: '$salida'\n"
    fi
}


function validar_parametros() {

    printf "\n############### Validaciones ###############\n"

    if [ "$cantidad_opciones" -lt 2 ]; then
        printf "+ Error 03 - Faltan parametros obligatorios. Debes proporcionar -s o -k.\n\n"
        exit 3
    fi

    if [ $flag_kill ] && [ $flag_salida ]; then
        printf "+ Error 04 - No se pueden enviar los parametros --salida (-s) y --kill (-k) a la vez.\n\n"
        exit 4
    fi

    if [ ! -d "$directorio" ]; then
        printf "+ Error 05 - El directorio especificado para monitorear no existe.\n\n"
        exit 5
    fi

    if [ -n "$salida" ] && [ ! -d "$salida" ]; then
        printf "+ Error 06 - El directorio de salida especificado no existe.\n\n"
        exit 6
    fi
}


function validar_job() {
    if pgrep -f "inotifywait -m -r -e create -e moved_to $directorio" > /dev/null; then
        printf "+ Error 07 - Ya existe un demonio activo para el directorio '$directorio_base'.\n\n"
        exit 7
    fi
}


function iniciar_job() {
    (
        inotifywait -m -r -e create -e moved_to "$directorio" | while read -r path action file; do
            full_path="$path$file"
            duplicados=$(find "$directorio" -type f -name "$file" ! -path "$full_path" -size "$(stat -c%s "$full_path")c")
            if [ -n "$duplicados" ]; then
                tar_file="$salida/$(date +'%Y%m%d_%H%M%S').tar.gz"
                if [ ! -f "$tar_file" ]; then
                    tar -czf "$tar_file" -C "$path" "$file"
                fi
            fi
        done
    ) &
    printf "+ Demonio iniciado en segundo plano.\n\n"
}


function finalizar_demonio() {
    pkill -f "inotifywait -m -r -e create -e moved_to $directorio"
    if [ $? -eq 0 ]; then
        printf "+ Demonio finalizado.\n\n"
    else
        printf "+ No se encontro ningun demonio en ejecucion para el directorio '$directorio_base'.\n\n"
        exit 0
    fi
}


############### MAIN ###############

# Capturo opciones
opciones=$(getopt -o d:,s:,k,h --l directorio:,salida:,kill,help -- "$@" 2> /dev/null)
if [ "$?" != "0" ]; then
    printf "+ Error 01 - Parametros ingresados invalidos."
    exit 1
fi

cantidad_opciones=0

# Asigno opciones a parametros
eval set -- "$opciones"
while true
do
    case "$1" in
        -d | --directorio)
            directorio="$2"
            cantidad_opciones=$((cantidad_opciones + 1))
            shift 2;;

        -s | --salida)
            salida="$2"
            flag_salida=true
            cantidad_opciones=$((cantidad_opciones + 1))
            shift 2;;

        -k | --kill)
            flag_kill=true
            cantidad_opciones=$((cantidad_opciones + 1))
            shift;;

        -h | --help)
            ayuda
            exit 0;;

        --)
            shift
            break;;

        *)
            printf "+ Error 02 - Error parseando parametros.\n"
            exit 2;;
    esac
done

directorio_base=$(basename "$directorio")

if [ $flag_kill ]; then
    finalizar_demonio
else
    validar_parametros
    mostrar_titulos "$cantidad_opciones"
    validar_job
    iniciar_job
fi
