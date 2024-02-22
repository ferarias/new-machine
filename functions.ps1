using namespace System.IO

# Create a folder for caching downloads
$cacheFolder = [Path]::Combine("$PSScriptRoot", ".cache")
Write-Host "INFO: Cache directory is: $cacheFolder"
New-Item -ItemType Directory -Force -Path $cacheFolder | Out-Null

Function Get-MyModule {
    Param(
        [string]$name
    )

    if (-not(Get-Module -name $name)) {
        if (Get-Module -ListAvailable |
            Where-Object { $_.name -eq $name }) {
            Import-Module -Name $name
            $true
        } 
        else { $false }
    } 
    else { $true }
} 


# 7-zip
if (!(Get-MyModule -name "7Zip4Powershell")) { 
    Write-Host -ForegroundColor Cyan "Installing required 7zip module in Powershell"
    Install-Module -Name "7Zip4Powershell" -Scope CurrentUser -Force 
}
Invoke-WebRequest "https://www.7-zip.org/a/7z2107-x64.exe" -Out "$cacheFolder\7z2107-x64.exe"
Expand-7Zip -ArchiveFileName "$cacheFolder\7z2107-x64.exe" -TargetPath "$cacheFolder\7z\"

Function Install-WinGetPackages {
    param (
        [parameter(Mandatory = $true)][string]$JsonFile
    )

    $data = Get-Content $jsonFile | ConvertFrom-Json

    $title = $data.Title

    Write-Host -ForegroundColor Green "INSTALLING $title"

    $data | Select-Object -ExpandProperty Packages | ForEach-Object {

        $command = "winget list --id $($_.id)"
        Invoke-Expression $command
        if (0 -ne $LASTEXITCODE) {
            $command = "winget install --id $($_.id)"
            if ($null -ne $_.scope) {
                $command = "$($command) --scope $($_.scope)"
            }
            if ($null -ne $_.interactive) {
                $command = "$($command) --interactive"
            }
            Invoke-Expression $command
        }

    }
}

Function Get-RemoteFiles {
    param (
        [parameter(Mandatory = $true)][string]$jsonFile,
        [parameter(Mandatory = $true)][string]$targetDir,
        [parameter(Mandatory = $true)][string]$toolsDir
    )
    
    Get-Content $jsonFile | ConvertFrom-Json | Select-Object -ExpandProperty items | ForEach-Object {
    
        $file = $_.file
        $url = $_.url
        $repo = $_.repo
        $type = $_.type
        $executable = $_.executable

        if ($Null -ne $repo) {
            # This is a GitHub repo. We need to find out the latest tag and then build the URI to that release file
            $releasesUri = "https://api.github.com/repos/$repo/releases"
            $releasesResponse = Invoke-WebRequest $releasesUri -UseBasicParsing | ConvertFrom-Json
            if ($Null -ne $releasesResponse) {
                $tag = $releasesResponse[0].tag_name
            }
            else {
                $tagsUri = "https://api.github.com/repos/$repo/tags"
                $tagsResponse = Invoke-WebRequest $tagsUri -UseBasicParsing | ConvertFrom-Json
                $tag = $tagsResponse[0].name
            }
            if ($Null -ne $url) {
                $url = $url -replace "{tag}", $tag
            }
            else {
                $url = "https://github.com/$repo/releases/download/$tag/$file"
            }
        }
        $output = "$targetDir\$file"
        if (![System.IO.File]::Exists($output)) {
    
            Write-Host -ForegroundColor Green " Downloading $file..."
            Invoke-WebRequest $url -Out $output   
        }
        else {
            Write-Host -ForegroundColor Gray " Already downloaded $file... skipped."
        }

        switch ($type) {
            "zip" {
                Write-Host -ForegroundColor Green " Extracting $file..."
                $sysInternalsPath = Join-Path $toolsDir "sysinternals"
                New-Item -ItemType Directory -Force -Path $sysInternalsPath | Out-Null
                Expand-PackedFile "$cacheFolder/SysinternalsSuite.zip" $sysInternalsPath
                Add-PathVariable $sysInternalsPath
            }
            "exe" { 
                Write-Host -ForegroundColor Green " Installing $file as $executable..."
                Copy-Item -Force -Path (Join-Path $cacheFolder $file) -Destination (Join-Path $toolsDir $executable)
            }
            "font" {
                $fontFile = Get-Item -Path (Join-Path $cacheFolder $file)
                $fontFolder = Join-Path $cacheFolder "fonts" $fontFile.BaseName
                Expand-PackedFile $fontFile.FullName $fontFolder

                if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
                    foreach ($fontItem in (Get-ChildItem -Path $fontFolder -Recurse | Where-Object {($_.Name -like '*.ttf') -or ($_.Name -like '*.OTF')})) {
                        Install-Font -FontFile $fontItem
                    }     
                } else {
                    Write-Warning "You need administrative permissions to install fonts"
                }
            }
            "CreateInstall" {
                Start-Process (Join-Path $cacheFolder $file) -ArgumentList "-silent"
            }
            "NullSoft" {
                Start-Process (Join-Path $cacheFolder $file) -ArgumentList "/S"
            }
            Default {}
        }
    }
}

Function Expand-PackedFile {
    param (
        [String]$archiveFile,
        [String]$targetFolder,
        [string]$zipFolderToCopy
    )
    $tempFolder = New-TemporaryDirectory
    try {
        if (Test-Path -LiteralPath $archiveFile) {
            # Create target directory
            New-Item -ItemType Directory -Force -Path $targetFolder | Out-Null
            # Extract to a temp folder
            Extract -Path $archiveFile -Destination $tempFolder | Out-Null
            # Move files to the final directory in systems folder
            if ($zipFolderToCopy -eq "") {
                Robocopy.exe $tempFolder $targetFolder /E /NFL /NDL /NJH /NJS /nc /ns /np /MOVE | Out-Null
            }
            else {
                Robocopy.exe $tempFolder/$zipFolderToCopy $targetFolder /E /NFL /NDL /NJH /NJS /nc /ns /np /MOVE | Out-Null
            }
        }
        else {
            Write-Host -ForegroundColor Red "ERROR: $archiveFile not found."
            exit -1
        }
    }
    finally {
        if (Test-Path $tempFolder) {
            Remove-Item $tempFolder -Force -Recurse | Out-Null
        }
    }
    
}

Function Extract([string]$Path, [string]$Destination) {
    $sevenZipApplication = "$cacheFolder\7z\7z.exe"
    $sevenZipArguments = New-Object String[] 4
    $sevenZipArguments[0] = 'x'
    $sevenZipArguments[1] = '-y'
    $sevenZipArguments[2] = '-o' + $Destination
    $sevenZipArguments[3] = $Path
    & $sevenZipApplication $sevenZipArguments | Out-Null
}

Function Add-PathVariable {
    param (
        [string]$addPath
    )
    if (Test-Path $addPath) {
        $regexAddPath = [regex]::Escape($addPath)
        $arrPath = $env:Path -split ';' | Where-Object { $_ -notMatch "^$regexAddPath\\?" }
        $env:Path = ($arrPath + $addPath) -join ';'
    }
    else {
        Throw "'$addPath' is not a valid path."
    }
}

function Install-Font {
    param
    (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][System.IO.FileInfo]$FontFile
    )
	
    #Get Font Name from the File's Extended Attributes
    $oShell = new-object -com shell.application
    $Folder = $oShell.namespace($FontFile.DirectoryName)
    $Item = $Folder.Items().Item($FontFile.Name)
    $FontName = $Folder.GetDetailsOf($Item, 21)
    try {
        switch ($FontFile.Extension) {
            ".ttf" { $FontName = $FontName + [char]32 + '(TrueType)' }
            ".otf" { $FontName = $FontName + [char]32 + '(OpenType)' }
        }
        $Copy = $true
        Write-Host ('Copying' + [char]32 + $FontFile.Name + '.....') -NoNewline
        Copy-Item -Path $fontFile.FullName -Destination ("C:\Windows\Fonts\" + $FontFile.Name) -Force
        #Test if font is copied over
        If ((Test-Path ("C:\Windows\Fonts\" + $FontFile.Name)) -eq $true) {
            Write-Host ('Success') -Foreground Yellow
        }
        else {
            Write-Host ('Failed') -ForegroundColor Red
        }
        $Copy = $false
        #Test if font registry entry exists
        If ($null -ne (Get-ItemProperty -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -ErrorAction SilentlyContinue)) {
            #Test if the entry matches the font file name
            If ((Get-ItemPropertyValue -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts") -eq $FontFile.Name) {
                Write-Host ('Adding' + [char]32 + $FontName + [char]32 + 'to the registry.....') -NoNewline
                Write-Host ('Success') -ForegroundColor Yellow
            }
            else {
                $AddKey = $true
                Remove-ItemProperty -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -Force
                Write-Host ('Adding' + [char]32 + $FontName + [char]32 + 'to the registry.....') -NoNewline
                New-ItemProperty -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $FontFile.Name -Force -ErrorAction SilentlyContinue | Out-Null
                If ((Get-ItemPropertyValue -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts") -eq $FontFile.Name) {
                    Write-Host ('Success') -ForegroundColor Yellow
                }
                else {
                    Write-Host ('Failed') -ForegroundColor Red
                }
                $AddKey = $false
            }
        }
        else {
            $AddKey = $true
            Write-Host ('Adding' + [char]32 + $FontName + [char]32 + 'to the registry.....') -NoNewline
            New-ItemProperty -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $FontFile.Name -Force -ErrorAction SilentlyContinue | Out-Null
            If ((Get-ItemPropertyValue -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts") -eq $FontFile.Name) {
                Write-Host ('Success') -ForegroundColor Yellow
            }
            else {
                Write-Host ('Failed') -ForegroundColor Red
            }
            $AddKey = $false
        }
		
    }
    catch {
        If ($Copy -eq $true) {
            Write-Host ('Failed') -ForegroundColor Red
            $Copy = $false
        }
        If ($AddKey -eq $true) {
            Write-Host ('Failed') -ForegroundColor Red
            $AddKey = $false
        }
        write-warning $_.exception.message
    }
    Write-Host
}

Function Add-Shortcut {
    param (
        [String]$ShortcutLocation,
        [String]$ShortcutTarget,
        [String]$ShortcutIcon,
        [String]$WorkingDir
    )
    $wshshell = New-Object -ComObject WScript.Shell
    $link = $wshshell.CreateShortcut($ShortcutLocation)
    $link.TargetPath = $ShortcutTarget
    if (-Not [String]::IsNullOrEmpty($WorkingDir)) {
        $link.WorkingDirectory = $WorkingDir
    }
    if (-Not [String]::IsNullOrEmpty($ShortcutIcon)) {
        $link.IconLocation = $ShortcutIcon
    }
    $link.Save() 
}

Function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}