
param (
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ })]
    [System.IO.FileInfo]$appConfig
)

#Function Region
function New-IntunePackage {

    param (
        [string]$applicationName,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ })]
        [string]$installFilePath,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ })]
        [System.IO.FileInfo]$setupFile,

        [Parameter(Mandatory = $true)]
        [string]$outputDirectory
    )

    try {

        $exePath = "$PSScriptRoot\bin\IntuneWinAppUtil.exe"
        $intunewinFileName = $setupFile.BaseName

        if (!(Test-Path $exePath)) {
            throw "IntuneWinAppUtil.exe not found at expected location.."
        }

        if (!($outputDirectory)) {
            New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
        }

        if (!($applicationName)) {
            $applicationName = "NewApplication_$(get-date -Format yyyyMMddhhmmss)"
            Write-Host "No application name given..`nGenerated name: $applicationName" -ForegroundColor Black -BackgroundColor Green
        }

        if (Test-Path -Path $installFilePath) {
            Write-Host "Creating installation media.." -ForegroundColor Black -BackgroundColor Green
            $proc = Start-Process -FilePath $exePath -ArgumentList "-c `"$installFilePath`" -s `"$setupFile`" -o `"$outputDirectory`" -q" -Wait -PassThru -WindowStyle Hidden
            while (Get-Process -id $proc.Id -ErrorAction SilentlyContinue) {
                Start-Sleep -Seconds 2
            }
            if (Test-Path "$outputDirectory\$intunewinFileName.intunewin") {
                return $(Get-ChildItem -Path "$outputDirectory\$intunewinFileName.intunewin")
            }
            else {
                throw "*.intunewin file not found where it should be. something bad happened."
            }
        }

    }

    catch {
        Write-Warning $_.exception.message
    }

}
#EndRegion

#region build
if (Test-Path $appConfig -ErrorAction SilentlyContinue) {

    $appRoot = Split-Path $appConfig -Parent
    $config = get-content $appConfig -raw | ConvertFrom-Yaml
    $param = @{
        applicationName = $config.application.appName
        installFilePath = "$appRoot\Source"
        setupFile       = $config.application.installFile
        outputDirectory = "$appRoot\Intunewin"
    }

    Push-Location "$appRoot\Source"
    New-IntunePackage @param
    Pop-Location
}
#EndRegion
