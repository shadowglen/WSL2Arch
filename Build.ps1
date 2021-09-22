param(
    [Parameter(Mandatory = $true)]
    [string] $DistroName,
    [Parameter(Mandatory = $true)]
    [string] $DistroDir,
    [Parameter(Mandatory = $true)]
    [string] $Username
)

Install-Module Poshstache
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$outDir = "$scriptDir\out"

if (-Not (Test-Path $outDir)) {
    New-Item $outDir -ItemType Directory
}

$credentials = [PSCustomObject] @{
    USERNAME = $Username
}
ConvertTo-PoshstacheTemplate -InputFile "$scriptDir\Dockerfile.mustache" -ParametersObject $(ConvertTo-Json $credentials) | Out-File "$outDir\Dockerfile" -Force

docker stop wsl2arch
docker rm wsl2arch
docker rmi wsl2arch:latest
docker build -t wsl2arch:latest $outDir
docker run -it --name wsl2arch wsl2arch:latest passwd $Username
docker export -o "$outDir\WSL2Arch.tar" wsl2arch

if (-Not (Test-Path $DistroDir)) {
    mkdir $DistroDir
}

wsl --unregister $DistroName
wsl --import $DistroName $DistroDir "$outDir\WSL2Arch.tar"

docker stop wsl2arch
docker rm wsl2arch
docker rmi wsl2arch:latest
Remove-Item "$outDir" -Recurse