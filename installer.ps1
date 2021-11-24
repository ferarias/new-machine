#Require -Version 5.0
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
        Misc    = [Path]::Combine($downloadsFolder, "misc.json") ;
    }

    # #############################################################################
    # MISC ADDITIONAL SOFTWARE
    # #############################################################################
    Write-Host -ForegroundColor DarkYellow "INSTALLING ADDITIONAL MISC SOFTWARE"
    Write-Host -ForegroundColor DarkGreen "Downloading misc additional packages from: $($downloads.Misc)"
    Get-RemoteFiles $downloads.Misc $cacheFolder

    Expand-PackedFile "$cacheFolder/SysinternalsSuite.zip" ( [Path]::Combine($ToolsDir, "sysinternals") )
    Copy-Item -Force -Path "$cacheFolder/nuget.exe" -Destination $ToolsDir
    Copy-Item -Force -Path "$cacheFolder/baretail.exe" -Destination $ToolsDir
    Copy-Item -Force -Path "$cacheFolder/bombardier-windows-amd64.exe" -Destination "$ToolsDir/bombardier.exe"
    Copy-Item -Force -Path "$cacheFolder/hey_windows_amd64" -Destination "$ToolsDir/hey.exe"
    Start-Process "$cacheFolder/wcol500e.exe"

    # Environment Variables
    [System.Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', [EnvironmentVariableTarget]::Machine)

    # Windows Features
    # List features: Get-WindowsOptionalFeature -Online
    Enable-WindowsOptionalFeature -Online -FeatureName 'Containers' -All
    Enable-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Hyper-V' -All
    Enable-WindowsOptionalFeature -Online -FeatureName 'VirtualMachinePlatform' -All
    Enable-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Windows-Subsystem-Linux' -All

    # Terminal
    winget install --id 'Microsoft.WindowsTerminal' --interactive
    winget install --id 'Microsoft.Powershell' --interactive --scope machine
    winget install --id 'JanDeDobbeleer.OhMyPosh' --interactive
    winget install --id '9P9TQF7MRM4R' --interactive # Windows Subsystem for Linux Preview
    winget install --id '9NBLGGH4MSV6' --interactive # Ubuntu

    # Office
    winget install --id '9MSPC6MP8FM4' --interactive # Microsoft Whiteboard
    winget install --id 'calibre.calibre' --interactive # Calibre

    # Utilities
    winget install --id '7zip.7zip' --interactive --scope machine
    winget install --id 'WinSCP.WinSCP' --interactive --scope machine
    winget install --id 'AgileBits.1Password' --interactive
    winget install --id 'PuTTY.PuTTY' --interactive --scope machine
    winget install --id 'ScooterSoftware.BeyondCompare4' --interactive

    # Communication
    winget install --id '9WZDNCRDK3WP' # Slack
    winget install --id '9WZDNCRFJ140' # Twitter
    winget install --id 'XP99J3KP4XZ4VV' # Zoom
    winget install --id '9N97ZCKPD60Q' # Unigram

    # Browsers
    winget install --id 'BraveSoftware.BraveBrowser' --interactive
    winget install --id 'Opera.Opera' --interactive --scope machine

    # Images
    winget install --id 'Learnpulse.Screenpresso' --interactive --scope machine

    # Media
    winget install --id 'XPDM1ZW6815MQM' # VLC
    winget install --id '9P4CLT2RJ1RS' --interactive # MusicBee
    winget install --id 'MusicBrainz.Picard' --interactive # MusicBrainz Picard

    # Git
    winget install --id 'Git.Git' --interactive --scope machine
    winget install --id 'GitHub.GitLFS' --interactive --scope machine
    winget install --id 'GitHub.cli' --interactive --scope machine
    winget install --id 'Axosoft.GitKraken' --interactive

    # Azure/AWS
    winget install --id 'Microsoft.AzureCLI' --interactive
    winget install --id 'Microsoft.AzureDataStudio' --interactive --scope machine
    winget install --id 'Amazon.AWSCLI' --interactive --scope machine

    # Dev Tools
    winget install --id 'Telerik.Fiddler' --interactive
    winget install --id 'Datalust.Seq' --interactive --scope machine
    winget install --id '9WZDNCRDMDM3' --interactive # NuGet Package Explorer
    winget install --id '9MXFBKFVSQ13' --interactive # ILSpy

    # IDE's
    winget install --id 'Microsoft.VisualStudio.2022.Professional' --interactive
    winget install --id 'Microsoft.VisualStudioCode' --interactive --scope machine
    winget install --id 'Postman.Postman' --interactive
    winget install --id 'HeidiSQL.HeidiSQL' --interactive --scope machine
    winget install --id '3T.Robo3T' --interactive --scope machine

    # Frameworks
    winget install --id 'OpenJS.NodeJS' --interactive --scope machine
    winget install --id 'Microsoft.dotnet' --interactive

    # Synology
    winget install --id 'Synology.DriveClient' --interactive --scope machine
    winget install --id 'Synology.NoteStationClient' --interactive --scope machine

    # Misc
    winget install --id 'eMClient.eMClient' --interactive --scope machine

    # winget install --id 'Docker.DockerDesktop' --interactive --scope machine

    Write-Host -ForegroundColor DarkYellow "FINISHED SETUP!"
}
catch { 
    Write-Error $_ 
}