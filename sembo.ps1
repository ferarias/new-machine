#Requires -Version 5.0

using namespace System.IO

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [String]
    $ToolsDir
)

. (Join-Path $PSScriptRoot functions.ps1)

Write-Host -ForegroundColor Magenta "*******************************"
Write-Host -ForegroundColor White   "SETUP FOR SEMBO SPECIFIC STUFF"
Write-Host -ForegroundColor Magenta "*******************************"

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
    $downloadsFolder = [Path]::Combine("$PSScriptRoot", "downloads")
    Write-Host "INFO: Downloads directory is: $downloadsFolder."
    $downloads = @{ 
        Sembo    = [Path]::Combine($downloadsFolder, "sembo.json") ;
    }

    # #############################################################################
    # GET SOFTWARE
    # #############################################################################
    Write-Host -ForegroundColor DarkYellow "INSTALLING SOFTWARE"
    Write-Host -ForegroundColor DarkGreen "Downloading packages from: $($downloads.Sembo)"
    Get-RemoteFiles $downloads.Sembo $cacheFolder

    # Install frameworks
    winget install --id 'OpenJS.NodeJS.LTS' --version 14.17.4 --scope machine
    winget install --id 'Microsoft.dotnet' --version 3.1.410.15736 # dotnet 3.1 SDK
    winget install --id 'Microsoft.dotnet' --version 5.4.121.42430 # dotnet 5.4 SDK

    # Install apps
    winget install --id '9WZDNCRDK3WP' # Slack
    winget install --id '9PBGKG2D4TB5' # KeePass
    Start-Process -FilePath "$cacheFolder/openconnect-gui-1.5.3-win32.exe" -ArgumentList "/S" # Uses Nullsoft installer

    Write-Host -ForegroundColor DarkYellow "FINISHED SEMBO SETUP!"
}
catch { 
    Write-Error $_ 
}    