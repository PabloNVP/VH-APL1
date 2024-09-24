<#
.SYNOPSIS
	Script para encontrar los ganadores semanales de las distintas agencias de lotería de la ciudad.

.DESCRIPTION
	El script analiza las jugadas de cada agencia brindadas en archivos csv y las compara con otro archivo csv que contienelas jugadas ganadoras, clasificando los resultados en un archivo json.

.PARAMETER directorio
	Especifica la ruta dónde se encontrarán los archivos csv a procesar. (obligatorio)

.PARAMETER archivo
	Especifica la ruta completa (incluyendo el nombre del archivo) dónde se escribirán los resultados.
	(no puede utilizase con -pantalla)

.PARAMETER pantalla
	Indica si la salida elegida será por pantalla.
	(no puede utilizarse con -archivo)

.EXAMPLE
	./Ejercicio1.ps1 -directorio directorioEjemplo/archivos -pantalla
#>

###                 INTEGRANTES                     ###
###     Vazquez Petracca, Pablo N.  - CONFIDENCE    ###
###     Rodriguez, Pablo            - CONFIDENCE    ###
###     Collazo, Ignacio Lahuel     - CONFIDENCE    ###
###     Pozzato, Alejo Martin       - CONFIDENCE    ###
###     Rodriguez, Emanuel          - CONFIDENCE    ###


Param(
	[Parameter(Mandatory=$true)]
	[ValidateScript({
		if (-not $_){
			throw "El parametro '-directorio' no puede estar vacio"
		}
		if (-not (Test-Path $_)){
			throw "El directorio especificado no existe"
		}
		return $true
	})]
	$directorio,

	[Parameter(Mandatory=$false)]
	[ValidateScript({
		if (-not $_){
			throw "El parametro '-archivo' no puede estar vacio"
		}
		
		$nombreArchivo = Split-Path -Path $_ -leaf #Extraigo el nombre del archivo
		if (-not $nombreArchivo.Contains('.')){
			throw "Se debe incluir un archivo de salida"
		}
		
		$rutaDirectorios = Split-Path -Path $_ -Parent #Extraigo la ruta de directorios
		
		if ($rutaDirectorios -and -not (Test-Path $rutaDirectorios)){
			throw "El directorio del archivo no existe"
		}

		return $true
	})]
	$archivo,

	[Parameter(Mandatory=$false)]
	[Switch] #Indica que el parametro no contiene valor
	$pantalla
)

if ($archivo -and $pantalla){
	throw "No se puede usar '-pantalla' y '-archivo' al mismo tiempo"
}

if (-not $archivo -and -not $pantalla){
	throw "Se debe especificar una salida: '-pantalla' o '-archivo'"
}


$archivos = Get-ChildItem -Path $directorio -Filter "*.csv" #Guardo los archivos csv que contiene el directorio
if (-not $?){	
	throw "Error al obtener los archivos csv"
}

#Busco el archivo que contiene los numeros ganadores
foreach ($arch in $archivos){
	try {
		if ((Get-Content $arch).Count -eq 1){
			$archivoGanadores = $arch
		}
	}
	catch {
		throw "Error al leer el archivo $($arch.FullName)"
	}
}

if (-not $archivoGanadores) {
    throw "No se encontró un archivo de ganadores válido."
}

#Almaceno el objeto que contiene los numeros ganadores
$numerosGanadores = (Import-csv -Path $archivoGanadores.FullName -Header "Num1", "Num2", "Num3", "Num4", "Num5")[0]
if (-not $?){
	throw "Error al importar el archivo de numeros ganadores"
}

#Guardo los numeros en un array 
$numerosGanadoresArray = @($numerosGanadores.Num1, $numerosGanadores.Num2, $numerosGanadores.Num3, $numerosGanadores.Num4, $numerosGanadores.Num5)

#Inicializo un hashmap para guardar los resultados
$resultados = @{
                        "4_aciertos" = @()
                        "5_aciertos" = @()
                        "3_aciertos" = @()
                }

#Proceso cada archivo
foreach ($arch in $archivos){
	if ($arch -ne $archivoGanadores){

		#Guardo las jugadas
		$jugadas = Import-Csv -Path $arch.FullName -Header "Id", "Num1", "Num2", "Num3", "Num4", "Num5"
		if (-not $?) {
            		Write-Warning "Fallo al importar el archivo: $($arch.FullName)"
            		continue  #Continúa con el siguiente archivo
        	}

		#Proceso cada jugada
		foreach ($jugada in $jugadas){
			$aciertos = 0
			
			#Convierto a array los numeros de la jugada actual	
			$numerosJugada = @($jugada.Num1, $jugada.Num2, $jugada.Num3, $jugada.Num4, $jugada.Num5)
				
			foreach ($numero in $numerosJugada){
					
				if ($numerosGanadoresArray -contains $numero){
					$aciertos++
				}
			}

			#Clasifico los aciertos
                	if ($aciertos -ge 3) {
                        	$resultados["$aciertos`_aciertos"] +=  @{
        						"agencia" = $arch.BaseName
        						"jugada" = $jugada.Id
    				}		
                	}
		}		
	}
}

#Genero archivo json
$jsonResultados = $resultados | ConvertTo-Json -Depth 3

#Elijo la salida correspondiente
if ($pantalla){
	Write-Output $jsonResultados
}
else{
	$jsonResultados | Out-File -FilePath $archivo
	if (-not $?){
		throw "Error al escribir el archivo json"
	}
	Write-Output "Se ejecutó correctamente"
}

