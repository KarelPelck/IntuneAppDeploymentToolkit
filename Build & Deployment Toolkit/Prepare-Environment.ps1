<#
Version 1.0 
Author: Karel Pelckmans
Script: Prepare-Environment.ps1

Description: 
Installs all modules and tools you need to use the build & deploy package scripts

Release notes: 
version 1.0: Original published version 

Script provided As Is with no warranties. 
#>

#region Config
$modules = @(
    "Powershell-Yaml",
    "AzureAD"
)
$win32CliUrl = "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/raw/master/IntuneWinAppUtil.exe"
$binPath = "$PSScriptRoot\bin"
$tempPath = "$PSScriptRoot\temp"
#endregion
#region Install missing modules
try {
    foreach ($m in $modules) {
        if (!(get-module "$m*" -ListAvailable)) {
            Write-Host "Installing $m module to currentUser.."
            Install-Module -Name $m -Scope CurrentUser -Force
        } else {
            Write-Host "$m module is already available!"
        }
    }
    #endregion
    #region Install cli tool
    if (!(Test-Path $binPath -ErrorAction SilentlyContinue)) {
        Write-Host "Creating the bin-folder and downloading the CLI Tool."
        New-Item $binPath -ItemType Directory -Force | out-null
        Start-BitsTransfer $win32CliUrl -Destination "$binPath\$(Split-Path $win32CliUrl -leaf)"
        if (!(Test-Path "$binPath\$(Split-Path $win32CliUrl -leaf)" -ErrorAction SilentlyContinue)) {
            throw "CLI tool not found after download.."
        }
    } else {
        if (!(Test-Path $binPath\$(Split-Path $win32CliUrl -leaf))) {
            Write-Host "Did not find the CLI tool in the bin folder. Getting the tool!"
            Start-BitsTransfer $win32CliUrl -Destination "$binPath\$(Split-Path $win32CliUrl -leaf)"
            if (!(Test-Path "$binPath\$(Split-Path $win32CliUrl -leaf)" -ErrorAction SilentlyContinue)) {
                throw "CLI tool not found after download.."
            }
        } else {
            New-Item $tempPath -ItemType Directory -Force | out-null
            Start-BitsTransfer $win32CliUrl -Destination "$tempPath\$(Split-Path $win32CliUrl -leaf)"
            $versionTemp = (Get-Item "$tempPath\$(Split-Path $win32CliUrl -leaf)" ).VersionInfo.FileVersion
            $versionBin = (Get-Item "$binPath\$(Split-Path $win32CliUrl -leaf)" ).VersionInfo.FileVersion
            Write-Host "Checking if you have the latest version of the CLI Tool"
            If ( $versionBin -eq $versionTemp ) {
                Write-Host "You have the latest version of the CLI tool!"
            } Else {
                Start-BitsTransfer $win32CliUrl -Destination "$binPath\$(Split-Path $win32CliUrl -leaf)"
                if (!(Test-Path "$binPath\$(Split-Path $win32CliUrl -leaf)" -ErrorAction SilentlyContinue)) {
                    throw "CLI tool not found after download.."
                }
            }
            #Clean up temp folder
            Remove-Item $tempPath -Recurse -Force
        } 
    }
    #endregion
}
catch {
    $errorMsg = $_.exception.message
}
finally {
    if ($errorMsg) {
        Write-Warning $errorMsg
        throw $errorMsg
    }
    else {
        Write-Host "Environment configured successfully!"
    }
}