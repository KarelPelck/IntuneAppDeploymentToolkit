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
    $Mode = "Install",
    [Parameter(Mandatory = $true)]
    [string]$appName
)

#REGION Functions
function Invoke-Process {
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$ArgumentList
    )

    $ErrorActionPreference = 'Stop'

    try {
        $stdOutTempFile = "$env:TEMP\$((New-Guid).Guid)"
        $stdErrTempFile = "$env:TEMP\$((New-Guid).Guid)"

        $startProcessParams = @{
            FilePath               = $FilePath
            ArgumentList           = $ArgumentList
            RedirectStandardError  = $stdErrTempFile
            RedirectStandardOutput = $stdOutTempFile
            Wait                   = $true;
            PassThru               = $true;
            NoNewWindow            = $true;
        }
        if ($PSCmdlet.ShouldProcess("Process [$($FilePath)]", "Run with args: [$($ArgumentList)]")) {
            $cmd = Start-Process @startProcessParams
            $cmdOutput = Get-Content -Path $stdOutTempFile -Raw
            $cmdError = Get-Content -Path $stdErrTempFile -Raw
            if ($cmd.ExitCode -ne 0) {
                if ($cmdError) {
                    throw $cmdError.Trim()
                }
                if ($cmdOutput) {
                    throw $cmdOutput.Trim()
                }
            }
            else {
                if ([string]::IsNullOrEmpty($cmdOutput) -eq $false) {
                    Write-Output -InputObject $cmdOutput
                }
            }
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
    finally {
        Remove-Item -Path $stdOutTempFile, $stdErrTempFile -Force -ErrorAction Ignore
    }
}

#END REGION


#Check if 64bit and restart script under 64bit if necessary 
$exitCode = 0

if (![System.Environment]::Is64BitProcess)
{
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
    $logFile = "C:\TEMP\$appName`.log" #for system user this will normally be C:/Windows/TEMP
    #endregion
    #region Logging
    Start-Transcript -Path $logFile -Force
    #endregion

    #region Process
    try {
        switch ($mode) {
            "Install" { 
                Invoke-Process -FilePath "C:\ProgramData\Chocolatey\choco.exe" -ArgumentList "install $appName -y"
            }
            "Uninstall" {
                Invoke-Process -FilePath "C:\ProgramData\Chocolatey\choco.exe" -ArgumentList "uninstall $appName -y"
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

exit $exitCode