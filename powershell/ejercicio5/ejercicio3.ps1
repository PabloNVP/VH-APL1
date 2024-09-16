###                 INTEGRANTES                     ###
###     Vazquez Petracca, Pablo N.  - CONFIDENCE    ###
###     Rodriguez, Pablo            - CONFIDENCE    ###
###     Collazo, Ignacio Lahuel     - CONFIDENCE    ###
###     Pozzato, Alejo Martin       - CONFIDENCE    ###
###     Rodriguez, Emanuel          - CONFIDENCE    ###

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
