$portName = "Port Name"
$printDriverName = "Driver Name"
$PrinterName = "PrinterName"

pnputil.exe /add-driver "$psscriptroot\Path\INfFileName.inf" /install
Add-PrinterDriver -Name "Driver name included in file"


$portExists = Get-Printerport -Name $portname -ErrorAction SilentlyContinue
if (-not $portExists) {
  Add-PrinterPort -name $portName -PrinterHostAddress "Port-IP-address/Hostname"
}
$printDriverExists = Get-PrinterDriver -name $printDriverName -ErrorAction SilentlyContinue
if ($printDriverExists) {
    Add-Printer -Name $PrinterName -PortName $portName -DriverName $printDriverName
}else{
    Write-Warning "Printer Driver not installed"
}
