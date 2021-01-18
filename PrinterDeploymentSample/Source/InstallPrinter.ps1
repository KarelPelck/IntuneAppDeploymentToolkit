Function Install-Printer {

<#
.SYNOPSIS
    Powershell Funtion for installing Printers.
 
.DESCRIPTION
    This powershell function will create a network printer port and install a network based printer.
 
.PARAMETER PortName 
    Printer Port Name for the printer
.PARAMETER PrinterDriverName 
    Driver name for the printer to be installed with
    
.PARAMETER PrinterName
    Name you want your printer to be known by
    
.PARAMETER PrinterHostAddress 
    Ipaddress or Hostname of the printer
 
.EXAMPLE
    Install-Printer -portname "Printerport_1" -PrintDriverName "Driver1 (Make sure this driver is installed on the system)" -PrinterName "Printer_1 (Topfloor)" -PrinterHostAddress "10.0.0.1"
 
.INPUTS
    None
 
.OUTPUTS
    System.IO.FileInfo
 
.NOTES
    Author:  Karel Pelckmans
    Website: https://Shellblazer.com
    Twitter: @karelpelck
#>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage='Printer Portname',
            Position=2)]
        [String]$portName,

        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage='Printer driver name',
            Position=3)]
        [String]$PrintDriverName,

        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage='Name of your Printer',
            Position=0)]
        [String]$PrinterName,

        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage='Ipaddress or hostname',
            Position=1)]
        [String]$PrinterHostAddress

    )

    Add-PrinterDriver -Name $printDriverName

    $portExists = Get-Printerport -Name $portname -ErrorAction SilentlyContinue
    if (-not $portExists) {
    Add-PrinterPort -name $portName -PrinterHostAddress $printerHostAddress
    }
    $printDriverExists = Get-PrinterDriver -name $printDriverName -ErrorAction SilentlyContinue
    if ($printDriverExists) {
        Add-Printer -Name $PrinterName -PortName $portName -DriverName $printDriverName
    }else{
        Write-Warning "Printer Driver not installed"
        Exit 1
    }

}


#Install Drivers on the system

$Drivers = Get-ChildItem -Path .\Drivers\ -Recurse -Filter "*.inf"
foreach ($driver in $drivers) {
    pnputil.exe /add-driver $driver.versioninfo.filename /install
}

#Import printer data from CSV
$Printers = Import-CSV -Path .\Printers.csv -Delimiter ";" -Encoding UTF8 

#Add Printers to the system

foreach ($printer in $Printers) {
    $printer | Install-Printer
}