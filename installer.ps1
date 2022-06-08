#Requires -Version 5.0
# #Requires -RunAsAdministrator

using namespace System.IO

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [String]
    $ToolsDir
)

. (Join-Path $PSScriptRoot functions.ps1)

Write-Host -ForegroundColor Magenta "***************************************"
Write-Host -ForegroundColor White   "SETUP FOR FERARIAS COMPUTER ENVIRONMENT"
Write-Host -ForegroundColor Magenta "***************************************"

# Environment Variables
[System.Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', [EnvironmentVariableTarget]::Machine)

try {
    # #############################################################################
    # SETUP BASIC STUFF
    # #############################################################################
    Write-Host -ForegroundColor DarkYellow "SETTING UP REQUIRED PATHS"
    # Setup some basic directories and stuff
    Write-Host "INFO: Running from $PSScriptRoot"
    New-Item -ItemType Directory -Force -Path $ToolsDir | Out-Null
    Write-Host "INFO: Tools Install directory is $ToolsDir"
    Add-PathVariable $ToolsDir

    # Set the files that will be downloaded in each section
    # You can take a look at the "downloads" folder to see which downloads are configured
    $downloadsFolder = Join-Path $PSScriptRoot "downloads"
    Write-Host "INFO: Downloads directory is: $downloadsFolder."
    $downloads = @{ 
        Fonts   = Join-Path $downloadsFolder "fonts.json"
        Misc    = Join-Path $downloadsFolder "misc.json"
    }

    Write-Host -ForegroundColor DarkGreen "Downloading packages from: $($downloads.Misc)"
    Get-RemoteFiles $downloads.Misc $cacheFolder
    Write-Host -ForegroundColor DarkGreen "Downloading fonts from: $($downloads.Fonts)"
    Get-RemoteFiles $downloads.Fonts $cacheFolder

    # #############################################################################
    # GET SOFTWARE
    # #############################################################################
    Write-Host -ForegroundColor DarkYellow "INSTALLING SOFTWARE"

    # Windows Features
    # List features: Get-WindowsOptionalFeature -Online
    Enable-WindowsOptionalFeature -Online -FeatureName 'Containers' -All
    Enable-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Hyper-V' -All
    Enable-WindowsOptionalFeature -Online -FeatureName 'VirtualMachinePlatform' -All
    Enable-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Windows-Subsystem-Linux' -All

    # Winget packages
    $packagesFolder = Join-Path $PSScriptRoot "packages"
    foreach ($item in Get-ChildItem -Path $packagesFolder -Filter "*.json" ) {
         Install-Packages -JsonFile $item
    }

    # Media
    winget install --id 'XPDM1ZW6815MQM' # VLC
    winget install --id '9P4CLT2RJ1RS' --interactive # MusicBee
    winget install --id 'MusicBrainz.Picard' --interactive # MusicBrainz Picard

    # Git
    winget install --id 'Git.Git' --interactive --scope machine
    winget install --id 'GitHub.GitLFS' --scope machine
    winget install --id 'GitHub.cli' --scope machine

    # Azure/AWS
    winget install --id 'Microsoft.AzureDataStudio' --interactive --scope machine
    winget install --id 'Microsoft.AzureCLI' --interactive
    winget install --id 'Amazon.AWSCLI' --interactive --scope machine

    # Dev Tools
    winget install --id 'Telerik.Fiddler'
    winget install --id 'Datalust.Seq' --interactive --scope machine
    winget install --id '9WZDNCRDMDM3' # NuGet Package Explorer
    winget install --id '9MXFBKFVSQ13' # ILSpy

    # IDE's
    winget install --id 'Microsoft.VisualStudio.2022.Professional' --interactive
    winget install --id 'Postman.Postman' --interactive
    winget install --id 'HeidiSQL.HeidiSQL' --interactive --scope machine
    winget install --id '3T.Robo3T' --interactive --scope machine

    # Frameworks
    winget install --id 'Microsoft.dotnet' --interactive
 
    # Synology
    winget install --id 'Synology.DriveClient' --interactive --scope machine
    winget install --id 'Synology.NoteStationClient' --interactive --scope machine

    # Misc
    winget install --id 'Corsair.iCUE.4' --interactive --scope machine

    # Additional software
    Start-Process "$cacheFolder/wcol500e.exe" -ArgumentList "-silent" # Uses CreateInstall 
    $sysInternalsPath =Join-Path $ToolsDir "sysinternals"
    Expand-PackedFile "$cacheFolder/SysinternalsSuite.zip" $sysInternalsPath
    Add-PathVariable $sysInternalsPath

    Copy-Item -Force -Path "$cacheFolder/nuget.exe" -Destination $ToolsDir
    Copy-Item -Force -Path "$cacheFolder/baretail.exe" -Destination $ToolsDir
    Copy-Item -Force -Path "$cacheFolder/bombardier-windows-amd64.exe" -Destination "$ToolsDir/bombardier.exe"
    Copy-Item -Force -Path "$cacheFolder/hey_windows_amd64" -Destination "$ToolsDir/hey.exe"
    Copy-Item -Force -Path "$cacheFolder/jq-win64.exe" -Destination "$ToolsDir/jq.exe"


    # Install fonts requires admin
    $fontFolder = Join-Path $cacheFolder "fonts/meslo"
    Expand-PackedFile "$cacheFolder/Meslo.zip" $fontFolder
    foreach ($FontItem in (Get-ChildItem -Path $fontFolder | Where-Object {($_.Name -like '*.ttf') -or ($_.Name -like '*.OTF')})) {
        Install-Font -FontFile $FontItem
    }     
    $fontFolder = Join-Path $cacheFolder "fonts/firacode"
    Expand-PackedFile "$cacheFolder/Fira_Code_v6.2.zip" $fontFolder
    foreach ($FontItem in (Get-ChildItem -Path $fontFolder | Where-Object {($_.Name -like '*.ttf')})) {
        Install-Font -FontFile $FontItem
    }     

    # winget install --id 'Docker.DockerDesktop' --interactive --scope machine

    winget install --id 'JanDeDobbeleer.OhMyPosh'
    oh-my-posh --init --shell pwsh --config ~/jandedobbeleer.omp.json | Invoke-Expression


    Write-Host -ForegroundColor DarkYellow "FINISHED SETUP!"
}
catch { 
    Write-Error $_ 
}