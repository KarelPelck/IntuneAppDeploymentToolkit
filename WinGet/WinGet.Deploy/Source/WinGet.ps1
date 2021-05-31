<#
Version 1.0 
Author: Karel Pelckmans
Script: WinGet.ps1

Dscription: 
Install application script template to deploy applications with Microsoft Intune. 

Release notes: 
version 1.0: Original published version 

Script provided As Is with no warranties. 
#>

Param( 
    [Parameter(Mandatory = $false)]
    [ValidateSet('Install', 'Uninstall')]
    $Mode = "Install",

    [Parameter(Mandatory = $false)]
    [switch]$AttLogon, 

    [Parameter(Mandatory = $false)]
    [DateTime]$At = "12:15pm"   
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
                $action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -command "& {WinGet upgrade --all --silent}"'
                
                if ($AttLogon) {
                    $trigger =  New-ScheduledTaskTrigger -AtLogOn
                } Else {
                    $trigger =  New-ScheduledTaskTrigger -Daily -At $At
                }
                
                Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "WinGet Upgrade All" -Description "Upgrades all winget installed packages."
            }
            "Uninstall" {
                #Removal Code 
                Unregister-ScheduledTask -TaskName "WinGet Upgrade All" -Confirm:$false
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
