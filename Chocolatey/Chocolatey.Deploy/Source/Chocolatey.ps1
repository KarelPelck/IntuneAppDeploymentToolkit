<#
Version 1.0 
Author: Karel Pelckmans
Script: Chocolatey.ps1

Dscription: 
Install application script template to deploy applications with Microsoft Intune. 

Release notes: 
version 1.0: Original published version 

Script provided As Is with no warranties. 
#>

Param( 
    [Parameter(Mandatory = $false)]
    [ValidateSet('Install', 'Uninstall')]
    $Mode = "Install"
)


#Check if 64bit and restart script under 64bit if necessary 
if (![System.Environment]::Is64BitProcess) {

    # start new PowerShell as x64 bit process, wait for it and gather exit code and standard error output
    $sysNativePowerShell = "$($PSHOME.ToLower().Replace("syswow64", "sysnative"))\powershell.exe"

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $sysNativePowerShell
    $pinfo.Arguments = "-ex bypass -file `"$PSCommandPath`""
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.CreateNoWindow = $true
    $pinfo.UseShellExecute = $false
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null

    $exitCode = $p.ExitCode

    $stderr = $p.StandardError.ReadToEnd()

    if ($stderr) { Write-Error -Message $stderr }

} 

Else {
    #Script region

    #region Config
    $appName = "Chocolatey"
    $logFile = "C:\temp\$appName`.log" #for system user this will normally be C:/Windows/TEMP
    #endregion
    #region Logging
    Start-Transcript -Path $logFile -Force
    #endregion

    #region Process
    try {
        switch ($mode) {
            "Install" { 
                Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
                Push-Location $env:ChocolateyInstall
                choco install choco-upgrade-all-at-startup -y 
                Pop-Location
            }
            "Uninstall" {
                if (!$env:ChocolateyInstall) {
                    Write-Warning "The ChocolateyInstall environment variable was not found. `n Chocolatey is not detected as installed. Nothing to do"
                    return
                }
                if (!(Test-Path "$env:ChocolateyInstall")) {
                    Write-Warning "Chocolatey installation not detected at '$env:ChocolateyInstall'. `n Nothing to do."
                    return
                }

                $userPath = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment').GetValue('PATH', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames).ToString()
                $machinePath = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager\Environment\').GetValue('PATH', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames).ToString()

                @"
User PATH:
$userPath

Machine PATH:
$machinePath
"@ | Out-File "C:\PATH_backups_ChocolateyUninstall.txt" -Encoding UTF8 -Force

                if ($userPath -like "*$env:ChocolateyInstall*") {
                    Write-Output "Chocolatey Install location found in User Path. Removing..."
                    # WARNING: This could cause issues after reboot where nothing is
                    # found if something goes wrong. In that case, look at the backed up
                    # files for PATH.
                    [System.Text.RegularExpressions.Regex]::Replace($userPath, [System.Text.RegularExpressions.Regex]::Escape("$env:ChocolateyInstall\bin") + '(?>;)?', '', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) | % { [System.Environment]::SetEnvironmentVariable('PATH', $_.Replace(";;", ";"), 'User') }
                }

                if ($machinePath -like "*$env:ChocolateyInstall*") {
                    Write-Output "Chocolatey Install location found in Machine Path. Removing..."
                    # WARNING: This could cause issues after reboot where nothing is
                    # found if something goes wrong. In that case, look at the backed up
                    # files for PATH.
                    [System.Text.RegularExpressions.Regex]::Replace($machinePath, [System.Text.RegularExpressions.Regex]::Escape("$env:ChocolateyInstall\bin") + '(?>;)?', '', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) | % { [System.Environment]::SetEnvironmentVariable('PATH', $_.Replace(";;", ";"), 'Machine') }
                }

                # Adapt for any services running in subfolders of ChocolateyInstall
                $agentService = Get-Service -Name chocolatey-agent -ErrorAction SilentlyContinue
                if ($agentService -and $agentService.Status -eq 'Running') { $agentService.Stop() }
                # TODO: add other services here

                # delete the contents (remove -WhatIf to actually remove)
                Remove-Item -Recurse -Force "$env:ChocolateyInstall"

                [System.Environment]::SetEnvironmentVariable("ChocolateyInstall", $null, 'User')
                [System.Environment]::SetEnvironmentVariable("ChocolateyInstall", $null, 'Machine')
                [System.Environment]::SetEnvironmentVariable("ChocolateyLastPathUpdate", $null, 'User')
                [System.Environment]::SetEnvironmentVariable("ChocolateyLastPathUpdate", $null, 'Machine')

                if ($env:ChocolateyToolsLocation) { Remove-Item -Recurse -Force "$env:ChocolateyToolsLocation" }
                [System.Environment]::SetEnvironmentVariable("ChocolateyToolsLocation", $null, 'User')
                [System.Environment]::SetEnvironmentVariable("ChocolateyToolsLocation", $null, 'Machine')
            }
            Default {
                Write-Host "Not the way to go!"
            }
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
    }
    finally {
        if ($errorMsg) {
            Write-Host $errorMsg
            Stop-Transcript
            throw $errorMsg
        }
        else {
            Write-Host "Script completed successfully.."
            Stop-Transcript
        }
    }
    #endregion
    
} #End Script region
