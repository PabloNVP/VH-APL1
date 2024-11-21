<#
.SYNOPSIS
    Consulta información relacionada al mundo de Star Wars.
.DESCRIPTION
    Este script consulta información relacionada al mundo de Star Wars a partir de
    ingresar el/los ID/s de los Personaje/s y/o ID/s de la/s Pelicula/s de la saga.
.PARAMETER people
    ID/s de los Personaje/s
.PARAMETER film
    ID/s de la/s Pelicula/s
.PARAMETER clear
    Limpia la memoria cache
.EXAMPLE
    Ejercicio5.ps1 -people 1,2 -film 1,2
.EXAMPLE
    ejercicio5.ps1 -film 1
.EXAMPLE
    ejercicio5.ps1 -clear
#>

############### INTEGRANTES ###############
###     Collazo, Ignacio Lahuel         ### 
###     Pozzato, Alejo Martin           ### 
###     Rodriguez, Emanual              ###
###     Rodriguez, Pablo                ### 
###     Vazquez Petracca, Pablo N.      ### 
###########################################

Param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({
        if($clear){
            throw "No puede utilizarse el parametro -clear con otro."
        }
        return $true
    })]
    [int[]]$people,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({
        if($clear){
            throw "No puede utilizarse el parametro -clear con otro."
        }
        return $true
    })]
    [int[]]$film,

    [Parameter(Mandatory = $false)]
    [ValidateScript({
        if($people -or $film){
            throw "No puede utilizarse el parametro -clear con otro."
        }
        return $true
    })]
    [switch]$clear
)

$path_people="$HOME/people.json"
$path_film="$HOME/film.json"

if($clear){
    Write-Host "Se está limpiando la memoria cache..." -ForegroundColor Yellow

    # Verifica si el archivo de personajes existe y lo elimina
    if (Test-Path $path_people) {
        Remove-Item $path_people -Force
        Write-Host "  [*] Limpieza de Personajes completa." -ForegroundColor Yellow
    }

    # Verifica si el archivo de películas existe y lo elimina
    if (Test-Path $path_film) {
        Remove-Item $path_film -Force
        Write-Host "  [*] Limpieza de Películas completa." -ForegroundColor Yellow
    }

    Write-Host "Se ha completado la limpieza de la memoria cache." -ForegroundColor Yellow
    exit 0;
}

if(-not $people -and -not $film){
    Write-Host "Error de sintaxis: Utilice Get-Help ./ejercicio5.ps1 para obtener ayuda." -ForegroundColor Red
    exit 1;
}

$uri_people="https://www.swapi.tech/api/people"
$uri_film="https://www.swapi.tech/api/films"

if($people){
    $first=0
    $json=@()

    if(Test-Path -Path "$path_people"){
        $get=Get-Content -Path "$path_people" | ConvertFrom-Json
        $json+=$get
    }

    foreach($id in $people){

        $query = $json | Where-Object { $_.Id -eq $id }

        if(-not $query){
            try{
                $obj = Invoke-RestMethod -Uri "$uri_people/$id"

                #Creo un nuevo objeto con el formato del personaje
                $newobj = [PSCustomObject]@{ 
                    Id = $($obj.result.uid)
                    Name = $($obj.result.properties.name)
                    Gender = $($obj.result.properties.gender)
                    Height = $($obj.result.properties.height)
                    Mass = $($obj.result.properties.mass)
                    "Birth Year" = $($obj.result.properties.birth_year)
                }

                $json += $newobj

                $newjson = $json | ConvertTo-Json

                Set-Content -Path "$path_people" -Value $newjson

                if($first -eq 0){
                    Write-Host "Personajes:" -ForegroundColor Green
                    $first=1
                }

                Write-Output $newobj
            }catch{
                if($($_.Exception.Response)){
                    Write-Host "No existe ningún Personaje con el id $id `n" -ForegroundColor Red
                }else{
                    Write-Host "Error: No se pudo conectar a Internet.`n" -ForegroundColor Red
                } 
            }
        }else{
            if($first -eq 0){
                Write-Host "Personajes:" -ForegroundColor Green
                $first=1
            }
            Write-Output $query
        }
    }
}

if($film){
    $first=0
    $json=@()

    if(Test-Path -Path "$path_film"){
        $get=Get-Content -Path "$path_film" | ConvertFrom-Json
        $json+=$get
    }

    foreach($id in $film){

        $query = $json | Where-Object { $_.Id -eq $id }

        if(-not $query){
            try{
                $obj = Invoke-RestMethod -Uri "$uri_film/$id"

                #Creo un nuevo objeto con el formato del personaje
                $newobj = [PSCustomObject]@{ 
                    Id = $($obj.result.uid)
                    Title = $($obj.result.properties.title)
                    "Episode id" = $($obj.result.properties.episode_id)
                    "Release date" = $($obj.result.properties.release_date)
                    "Opening crawl" = $($obj.result.properties.opening_crawl)
                }
                
                $json += $newobj

                $newjson = $json | ConvertTo-Json

                Set-Content -Path "$path_film" -Value $newjson

                if($first -eq 0){
                    Write-Host "Peliculas:" -ForegroundColor Green
                    $first=1
                }

                Write-Output $newobj
            }catch{
                if($($_.Exception.Response)){
                    Write-Host "No existe ninguna Pelicula con el id $id `n" -ForegroundColor Red
                }else{
                    Write-Host "Error: No se pudo conectar a Internet.`n" -ForegroundColor Red
                }
            }
        }else{
            if($first -eq 0){
                Write-Host "Peliculas:" -ForegroundColor Green
                $first=1
            }
            Write-Output $query
        }
    }
}
