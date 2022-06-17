#Requires -Version 5.0
# Requires -RunAsAdministrator


[CmdletBinding()]
param (
    [Parameter(HelpMessage='Set of installation packages and downloads')]
    [string]
    $PackageSet = "default",
    [Parameter(Mandatory)]
    [String]
    $ToolsDir
)

. (Join-Path $PSScriptRoot functions.ps1)

Write-Host -ForegroundColor Magenta "************************************"
Write-Host -ForegroundColor White   "SETUP A NEW COMPUTER ENVIRONMENT    "
Write-Host -ForegroundColor White   "Installing packages from $PackageSet"
Write-Host -ForegroundColor Magenta "************************************"

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
    # Look into "windows-features.json" file to see which Windows features are configured
    $winFeaturesFile = Join-Path $PSScriptRoot $PackageSet "windows-features.json"
    if(Test-Path -Path $winFeaturesFile -PathType Leaf) {
        Write-Host "INFO: Windows features file is: $winFeaturesFile."
        Get-Content $winFeaturesFile | ConvertFrom-Json | Select-Object -ExpandProperty features | ForEach-Object {
            $feature = $_
            Write-Host "INFO: Installing Windows feature: $feature"
            Enable-WindowsOptionalFeature -Online -FeatureName $feature -All
        }
    }

    # #############################################################################
    # INSTALL SOFTWARE
    # #############################################################################
    Write-Host -ForegroundColor DarkYellow "INSTALLING SOFTWARE"

    # # Winget packages
    $packagesFolder = Join-Path $PSScriptRoot $PackageSet "packages"
    Write-Host "INFO: Packages directory is: $packagesFolder."
    foreach ($item in Get-ChildItem -Path $packagesFolder -Filter "*.json" ) {
        Install-WinGetPackages -JsonFile $item
    }

    # Additional software
    # Look into the "downloads" folder to see which downloads are configured
    $downloadsFolder = Join-Path $PSScriptRoot $PackageSet "downloads"
    Write-Host "INFO: Downloads directory is: $downloadsFolder."
    foreach ($item in Get-ChildItem -Path $downloadsFolder -Filter "*.json" ) {
        Get-RemoteFiles -jsonFile $item -targetDir $cacheFolder -toolsDir $ToolsDir
    }

    # Post-installation steps
    # Look into "post-installation.json" file to see which post-installation steps are configured
    $postInstallationFile = Join-Path $PSScriptRoot $PackageSet "post-installation.json"
    if(Test-Path -Path $postInstallationFile -PathType Leaf) {
        Write-Host "INFO: Post-installation steps file is: $postInstallationFile."
        Get-Content $postInstallationFile | ConvertFrom-Json | Select-Object -ExpandProperty commands | ForEach-Object {
            $command = $_
            Write-Host "INFO: Running post-installation step: $command"
            $command | Invoke-Expression
        }
    }

    Write-Host -ForegroundColor DarkYellow "FINISHED SETUP!"
}
catch { 
    Write-Error $_ 
}