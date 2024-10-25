# +----------------------------------------+
    # | Grupo |    Integrantes             |
    # -------------------------------------|
    # |       | Collazo, Ignacio           |
    # |  01   | Pozzato, Alejo             |
    # |       | Rodriguez, Emanuel         |
    # |       | Rodriguez, Pablo           |
    # |       | Vazquez Petracca, Pablo    |
    # +------------------------------------+

<#
    .SYNOPSIS
    Este script realiza el monitoreo en segundo plano de los archivos de un directorio especificado.

    .DESCRIPTION
    Monitorea un directorio (incluyendo los subdirectorios) y valida si se esta generando un archivo duplicado, y en caso de ocurrir, se genera un log y se archiva en un archivo comprimido. 

    .PARAMETER directorio
    Ruta del directorio a monitorear.

    .PARAMETER salida
    Ruta del directorio en donde se van a crear los backups.

    .PARAMETER kill
    Flag que se utiliza para indicar que el script debe detener el demonio previamente iniciado. Este parametro solo se puede usar junto con -directorio.

    .EXAMPLE
    .\Ejercicio4.ps1 -directorio "./archivos" -salida "./backups"
    Este ejemplo especifica el directorio a monitorear, y el directorio destino donde se deben generar los .zip de backup correspondiente.

    .EXAMPLE
    .\Ejercicio4.ps1 -directorio "C:/users/test/Powershell/archivos" -salida "C:/users/test/Powershell/backups"
    Este ejemplo especifica el directorio a monitorear, y el directorio destino donde se deben generar los .zip de backup correspondiente, utilizando los paths absolutos.

    .EXAMPLE
    .\Ejercicio4.ps1 -directorio "./archivos" -kill
    Este ejemplo muestra la manera de finalizar el demonio utilizando el parametro "kill".

    .NOTES
    + Autor: Grupo 01 - Jueves TN
    + Tener en cuenta el encoding de los archivos, debido a que la condicion de duplicado es: mismo nombre de archivo y tamanio en bytes
    

    Tabla de codigos de error:
    +----------------------------------------------------------------------------------------+
    |  Codigo |                             Descripcion                                      |
    -----------------------------------------------------------------------------------------|
    |    01   | Falta(n) parametro(s) obligatorio(s).                                        |
    |    02   | No se pueden enviar los parametros -salida y -kill a la vez.                 |
    |    03   | El directorio especificado a monitorear, no existe.                          |
    |    04   | El directorio especificado para crear los backups, no existe.                |
    +----------------------------------------------------------------------------------------+
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$directorio,

    [Parameter(Mandatory=$false)]
    [string]$salida,

    [Parameter(Mandatory=$false)]
    [switch]$kill
)


function validacion_principal {
    if (-not $salida -and -not $kill) {
        Write-Error "+ Error 01 - Debes proporcionar al menos el parametro '-salida' o el parametro '-kill'."
        exit 1
    }
    if ($salida -and $kill) {
        Write-Error "+ Error 02 - No se pueden utilizar los parametros '-salida' y '-kill' a la vez."
        exit 2
    }
}


function validar_parametros {
    if (-not (Test-Path $directorio)) {
        Write-Error "+ Error 03 - El directorio especificado para monitorear, no existe."
        exit 3
    }

    if ($salida -and (-not (Test-Path $salida))) {
        Write-Error "+ Error 04 - El directorio de salida especificado no existe."
        exit 4
    }
}


function validar_job {
    try {
        $job = Get-Job | Where-Object { $_.State -eq 'Running' -and $_.Name -eq "monitoreo_$($directorio_base)" }

        if ($job) {
            Write-Output "+ Ya existe un demonio activo para el directorio '$directorio_base'."
            exit 0
        }
    } catch {
        Write-Error "+ Ocurrio un error al intentar validar el job: $_"
    }
}


function iniciar_job {
    Start-Job -Name "monitoreo_$($directorio_base)" -ScriptBlock {
        param ($directorio, $salida)

        $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path = $directorio
        $watcher.IncludeSubdirectories = $true
        $watcher.EnableRaisingEvents = $true
        $watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite, Size'

        $timestamp = Get-Date -Date "01/01/2000"
        $tiempo_espera = 400  # Tiempo para evitar 2 eventos seguidos y que se generen 2 zip

        $action = {
            $file = Get-Item -Path $Event.SourceEventArgs.FullPath

            if (((Get-Date) - $timestamp).TotalMilliseconds -ge $tiempo_espera) {
                $timestamp = Get-Date

                $duplicado = $false
                $files_en_directorio = Get-ChildItem -Path $directorio -Recurse -File

                foreach ($otro_file in $files_en_directorio) {
                    if ($otro_file.FullName -ne $file.FullName -and
                        $otro_file.Name -eq $file.Name -and
                        $otro_file.Extension -eq $file.Extension -and
                        $otro_file.Length -eq $file.Length) {
                        $duplicado = $true # Si esta duplicado, sale
                        break
                    }
                }

                if ($duplicado) {
                    $zipFile = Join-Path $salida "$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
                    Compress-Archive -Path $file.FullName -DestinationPath $zipFile
                }
            }
        }

        Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action
        Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action
        Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action
        Register-ObjectEvent -InputObject $watcher -EventName Modified -Action $action

        Write-Output "+---- Monitoreando directorio: '$($watcher.Path)' ----+"
        Register-EngineEvent PowerShell.Exiting -Action {
            Unregister-Event -SourceIdentifier FileSystemWatcherEvent
        }
        Wait-Event -SourceIdentifier FileSystemWatcherEvent
    } -ArgumentList $directorio, $salida > $null
    Write-Output "+ Demonio iniciado en segundo plano."
}


function finalizar_demonio {
    try {
        $job = Get-Job | Where-Object {
            $_.State -eq 'Running' -and $_.Name -eq "monitoreo_$($directorio_base)"
        }

        if ($job) {
            $job | ForEach-Object {
                Stop-Job -Id $_.Id
                Remove-Job -Id $_.Id
            }
            Write-Output "+ Demonio finalizado."
        } else {
            Write-Output "+ No se encontro ningun demonio en ejecucion para el directorio '$directorio_base'."
        }
    } catch {
        Write-Error "+ Error - $_"
    }
}


#########################################################################################


try {
    validacion_principal
    
    validar_parametros
    $directorio = Resolve-Path -Path $directorio
    $directorio_base = Split-Path -Path $directorio -Leaf

    if ($kill) {
        finalizar_demonio
    } else {
        $salida = Resolve-Path -Path $salida
        validar_job
        iniciar_job
    }
} catch {
    Write-Error "+ Error - $_"
}
