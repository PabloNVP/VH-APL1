<#
.SYNOPSIS
    Script para encontrar archivos duplicados en un directorio, comparando por nombre y tamaño.
    
.DESCRIPTION
    Este script recursivamente busca archivos en el directorio especificado, 
    comparando por nombre y tamaño, y muestra la lista de archivos duplicados junto con sus rutas.

.PARAMETER directorio
    Especifica el directorio en el que se desea buscar archivos duplicados.

.EXAMPLE
    .\script.ps1 -directorio "Ruta\al\directorio"
    Busca archivos duplicados en el directorio especificado y muestra los resultados.

.EXAMPLE
    Get-Help .\script.ps1
    Muestra la ayuda del script.
    
.NOTES
    Autor: Vazquez Petracca, Pablo N., Rodriguez, Pablo, Collazo, Ignacio Lahuel, Pozzato, Alejo Martin, Rodriguez, Emanuel
    Fecha: 2024-09-18
#>

############### INTEGRANTES ###############
###     Collazo, Ignacio Lahuel         ### 
###     Pozzato, Alejo Martin           ### 
###     Rodriguez, Emanual              ###
###     Rodriguez, Pablo                ### 
###     Vazquez Petracca, Pablo N.      ### 
###########################################

param(
    [Parameter(Mandatory=$True)][string]$directorio
)

# Validación de existencia del directorio
if (-not (Test-Path $directorio)) {
    Write-Output "El directorio especificado no existe: $directorio"
    exit
}

# Obtención de archivos, incluyendo subdirectorios
$archivos = Get-ChildItem -Path $directorio -File -Recurse

# Agrupar archivos por Nombre y Tamaño
$archivosDuplicados = $archivos | Group-Object Name, Length | Where-Object { $_.Count -gt 1 }

# Mostrar el resultado
if ($archivosDuplicados.Count -eq 0) {
    Write-Output "No se encontraron archivos duplicados."
} else {
    foreach ($grupo in $archivosDuplicados) {
        # Mostrar el nombre del archivo
        Write-Output "$($grupo.Name) ($($grupo.Group[0].Length) bytes)"
        
        # Mostrar las rutas donde están los duplicados
        foreach ($archivo in $grupo.Group) {
            Write-Output $archivo.FullName
        }

        Write-Output "" # Salto de linea
    }
}
