# choose a name for the Nano Server computer
$nanoComputerName = 'NewNano'

# First, mount the Windows Server Technical Preview ISO and enter the path to it
$mediaPath = 'G:\'

# setting up the directory in which the files will be copied and necessary directories will be created
$workingDirectoryPath = 'C:\temp\'
$workingDirectoryName = 'NanoServer'
$workingDirectory = Join-Path $workingDirectoryPath $workingDirectoryName

if ( -not (Test-Path -Path $workingDirectory) ) {
    New-Item -Path $workingDirectoryPath -ItemType Directory -Name $workingDirectoryName
}

cd $workingDirectory

# download necessary scripts, see 
# http://blogs.technet.com/b/nanoserver/archive/2015/06/16/powershell-script-to-build-your-nano-server-image.aspx
$ConvertWindowsImageScript = 'https://gallery.technet.microsoft.com/scriptcenter/Convert-WindowsImageps1-0fe23a8f/file/59237/7/Convert-WindowsImage.ps1'
$NanoServerScript = 'http://blogs.technet.com/cfs-filesystemfile.ashx/__key/telligent-evolution-components-attachments/01-10474-00-00-03-65-09-88/NanoServer.ps1'
$ConvertWindowsImageScriptDest = Join-Path $workingDirectory 'Convert-WindowsImage.ps1'
$NanoServerScriptDest = Join-Path $workingDirectory 'NanoServer.ps1'
Invoke-WebRequest $ConvertWindowsImageScript -OutFile $ConvertWindowsImageScriptDest
Invoke-WebRequest $NanoServerScript -OutFile $NanoServerScriptDest


# for non US-localized computer, in NanoServer.ps1 script replace line
# [String]$Language = [System.Globalization.CultureInfo]::CurrentCulture.Name.ToLower(),
# with line     
# [String]$Language = "en-us",
if ( (Get-Culture) -ne "en-us" ) {
    (Get-Content .\NanoServer.ps1).replace('[System.Globalization.CultureInfo]::CurrentCulture.Name.ToLower()', '"en-us"') | Set-Content .\NanoServer.ps1
}

# avoid digital signature check only for current session
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# dot source the modified NanoServer.ps1 script, MyNanoServer.ps1
. .\NanoServer.ps1

New-NanoServerImage -MediaPath $mediaPath -BasePath .\Base -TargetPath .\FirstSteps -ComputerName $nanoComputerName -GuestDrivers -EnableIPDisplayOnBoot

# create and boot a Nano Server VM
$VmName = "FirstNanoVM"
$VmMemory = 512MB
$VhdRootPath = Join-Path $workingDirectory "FirstSteps"
$VhdName = 'FirstSteps.vhd'
$VhdPath = Join-Path $VhdRootPath $VhdName
$switchName = 'Virtual Switch'
New-VM –Name $VmName –MemoryStartupBytes $VmMemory –VHDPath $VhdPath -SwitchName $switchName
Start-VM -Name $VmName

# retrieve the IP address of the Nano server VM
$VmIpAddresses = Get-VM -Name $VmName | select -ExpandProperty networkadapters | select ipaddresses
$ip = $VmIpAddresses.IPAddresses[0]
 
# to enable  Powershell remoting in a non-domain scenario, add the IP address of the Nano Server to the trusted hosts list
Enable-PSRemoting -SkipNetworkProfileCheck -Force
Get-Item wsman:\localhost\Client\TrustedHosts
Set-Item WSMan:\localhost\Client\TrustedHosts $ip -Concatenate -Force



############################################################
# first session on Nano Server through Powershell remoting #
############################################################

$user = “$ip\Administrator”

$ns = New-PSSession -ComputerName $ip -Credential $user
Enter-PSSession $ns

# do some work
Function prompt {“NanoServer> “}
pwd
mkdir temp
cd temp
New-Item -ItemType File -Name NanoServerRocks.ps1 | Set-Content -Value "Write-Output 'Nano Server Rocks!'"
.\NanoServerRocks.ps1

# show adapter is working
ping www.google.it

# see what's available in Nano Server
Get-Module -ListAvailable
Get-Command
Get-Command | measure

# exit session
Exit-PSSession

# show file copy through PS session
Copy-Item -FromSession $ns -Path 'C:\Users\Administrator\Documents\temp\NanoServerRocks.ps1' -Destination $workingDirectory

#close session
Remove-PSSession -Session $ns


# alternatively you may run commands remotely
Invoke-Command -ComputerName $ip -Credential $user -ScriptBlock {Get-Culture}


Stop-VM -Name $VmName