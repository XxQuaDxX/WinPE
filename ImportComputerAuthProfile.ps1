## Variables
$InstallDir = (Get-Location).Path

#region Functions
function Test-WinPE { return Test-Path -Path Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlset\Control\MiniNT }
function Start-WiredAutoConfig {
    If(!(Test-WinPE)){ Start-Process cmd -ArgumentList '/c sc config "dot3svc" start= auto' -Wait -NoNewWindow -ErrorAction SilentlyContinue}
    Start-Process cmd -ArgumentList "/c Net Start dot3svc" -NoNewWindow -Wait -ErrorAction SilentlyContinue
}
function Import-8021x {
    If(Test-WinPE){ $InstallDir = "X:\Custom" }else{ $InstallDir = (Get-Location).Path }
    $Args1 = '/c certutil.exe -addstore Root "' + $InstallDir + '\Certs\root.cer"'
    Start-Process cmd -ArgumentList $Args1 -NoNewWindow -Wait -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    $Args2 = '/c certutil.exe -ImportPFX -f -p CERTPWDHERE "' + $InstallDir + '\Certs\ComputerAuthCert.pfx"'
    Start-Process cmd -ArgumentList $Args2 -NoNewWindow -Wait -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    $Args3 = '/c netsh lan add profile filename="' + $InstallDir + '\ComputerAuthProfile.xml" interface=*'
    Start-Process cmd -ArgumentList $Args3 -NoNewWindow -Wait -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}
function Reset-NetworkInterface {
    $Args1 = '/c netsh lan reconnect interface=*'
    $Args2 = '/c netsh interface set interface name="ethernet" admin=DISABLED'
	$Args3 = '/c netsh interface set interface name="ethernet" admin=ENABLED'
	$CheckNetwork = netsh lan show interfaces
	While ($CheckNetwork -like "*there is no interface on the system*") {
		$wshell = New-Object -ComObject Wscript.Shell
		$Result = $wshell.Popup("There is no adapter on the machine. Please reconnect the network adapter.", 0, "WinPE Network Check", 5)
		If ($Result -eq 2) { Stop-Computer -Force }
		$CheckNetwork = netsh lan show interfaces
	}
	Start-Process cmd -ArgumentList $Args1 -NoNewWindow -Wait -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process cmd -ArgumentList $Args2 -NoNewWindow -Wait -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process cmd -ArgumentList $Args3 -NoNewWindow -Wait -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}
function Get-NetworkReadiness {
	$ping = $null
	$ping = (Get-WmiObject win32_networkadapterconfiguration | Where-Object { (($_.DNSDomain -eq "contoso.com") -or ($_.DefaultIPGateway -like "10.*")) }).IPAddress
	If($Ping -eq $null){ Return $False } else { Return $True }
}
#endregion Functions

Write-Host "Checking for Existing Maintenance Task Sequence..."
If(Test-Path "C:\Temp\WinMaintenance.txt"){ Write-Host "Found existing Maintenance Task Sequence! Not doing network check!"; Start-Sleep -Seconds 3; Exit 0 } else { Write-Host "No existing Maintenance Task Sequence found..." }

Write-Host "Checking Network Status..."
Start-Sleep -Seconds 5
If(Get-NetworkReadiness){ Exit 0 } else { Write-Host "Network not ready... Running 802.1x Script..." }

Write-Host "Starting Wired Auto Config Service..."
Start-WiredAutoConfig

Write-Host "Importing 802.1x Profile into Network Adapter..."
Import-8021x

Write-Host "Reseting Network Interface..."
Reset-NetworkInterface

Write-Host "Waiting for Adapter to have correct IP.." -NoNewline
$ping = Get-NetworkReadiness
While ($ping -eq $false) { 
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
    $ping = Get-NetworkReadiness
}

Write-Host "Finished"
Start-Sleep -Seconds 3
