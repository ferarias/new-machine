#Requires -Version 5.0
# Requires -RunAsAdministrator


[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [String]
    $ToolsDir
)

. (Join-Path $PSScriptRoot functions.ps1)

Write-Host -ForegroundColor Magenta "********************************"
Write-Host -ForegroundColor White   "SETUP A NEW COMPUTER ENVIRONMENT"
Write-Host -ForegroundColor Magenta "********************************"

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

    # #############################################################################
    # WINDOWS FEATURES
    # #############################################################################
    # List features: Get-WindowsOptionalFeature -Online
    Enable-WindowsOptionalFeature -Online -FeatureName 'Containers' -All
    Enable-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Hyper-V' -All
    Enable-WindowsOptionalFeature -Online -FeatureName 'VirtualMachinePlatform' -All
    Enable-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Windows-Subsystem-Linux' -All

    # #############################################################################
    # INSTALL SOFTWARE
    # #############################################################################
    Write-Host -ForegroundColor DarkYellow "INSTALLING SOFTWARE"

    # # Winget packages
    $packagesFolder = Join-Path $PSScriptRoot "packages"
    Write-Host "INFO: Packages directory is: $packagesFolder."
    foreach ($item in Get-ChildItem -Path $packagesFolder -Filter "*.json" ) {
        Install-WinGetPackages -JsonFile $item
    }

    # Additional software
    # Look into the "downloads" folder to see which downloads are configured
    $downloadsFolder = Join-Path $PSScriptRoot "downloads"
    Write-Host "INFO: Downloads directory is: $downloadsFolder."
    foreach ($item in Get-ChildItem -Path $downloadsFolder -Filter "*.json" ) {
        Get-RemoteFiles -jsonFile $item -targetDir $cacheFolder -toolsDir $ToolsDir
    }

    oh-my-posh --init --shell pwsh --config ~/jandedobbeleer.omp.json | Invoke-Expression


    Write-Host -ForegroundColor DarkYellow "FINISHED SETUP!"
}
catch { 
    Write-Error $_ 
}