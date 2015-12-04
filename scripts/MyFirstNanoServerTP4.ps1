# choose a name for the Nano Server computer
$nanoComputerName = 'NanoServerTP4'

# First, mount the Windows Server Technical Preview ISO and retrieve its path
$isoPath = 'D:\software\Windows-Server-2016\10586.0.151029-1700.TH2_RELEASE_SERVER_OEMRET_X64FRE_EN-US.ISO'
$mountResult = Mount-DiskImage -ImagePath $isoPath -PassThru
$driveLetter = ($mountResult | Get-Volume).DriveLetter
$mediaPath = $driveLetter + ':'

# setting up the directory in which the files will be copied and necessary directories will be created
$workingDirectoryPath = 'D:\temp\'
$workingDirectoryName = 'NanoServerTP4'
$workingDirectory = Join-Path $workingDirectoryPath $workingDirectoryName

if ( -not (Test-Path -Path $workingDirectory) ) {
    New-Item -Path $workingDirectoryPath -ItemType Directory -Name $workingDirectoryName
}

cd $workingDirectory

# copy helper scripts to working directory
$HelperScriptsPath = Join-Path $mediaPath 'NanoServer'
$ConvertWindowsImageScript = 'Convert-WindowsImage.ps1'
$ConvertWindowsImageScriptPath = Join-Path $HelperScriptsPath $ConvertWindowsImageScript
Copy-Item $ConvertWindowsImageScriptPath .
$NanoServerImageGeneratorScript = 'NanoServerImageGenerator.psm1'
$NanoServerImageGeneratorScriptPath = Join-Path $HelperScriptsPath $NanoServerImageGeneratorScript
Copy-Item $NanoServerImageGeneratorScriptPath .

# for non US-localized computer, in NanoServerImageGenerator.psm1 module replace line
# [String]$Language = [System.Globalization.CultureInfo]::CurrentCulture.Name.ToLower(),
# with line     
# [String]$Language = "en-us",
# first, remove read-only attribute in order to enable editing
$file = Get-Item '.\NanoServerImageGenerator.psm1'
if ( $file.IsReadOnly ) {
    $file.IsReadOnly = $false
}
# perform string replacing
if ( (Get-Culture) -ne "en-us" ) {
    (Get-Content .\NanoServerImageGenerator.psm1).replace('[System.Globalization.CultureInfo]::CurrentCulture.Name.ToLower()', '"en-us"') | Set-Content .\NanoServerImageGenerator.psm1
}

Import-Module .\NanoServerImageGenerator.psm1 -Verbose

# avoid digital signature check only for current session
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# create a Nano Server VHD
#New-NanoServerImage -MediaPath $mediaPath -BasePath .\Base -TargetPath .\FirstSteps\NanoServerTP4.vhd -ComputerName $nanoComputerName –GuestDrivers -Verbose
# create a Nano Server VHD with support for DSC 
New-NanoServerImage -MediaPath $mediaPath -BasePath .\Base -TargetPath .\FirstSteps\NanoServerTP4.vhd -ComputerName $nanoComputerName –GuestDrivers -Packages Microsoft-NanoServer-DSC-Package -Verbose

# add support for DSC to the Nano Server VHD TODO debug
#Edit-NanoServerImage -BasePath .\Base -TargetPath .\FirstSteps\NanoServerTP4.vhd -ComputerName $nanoComputerName -Packages Microsoft-NanoServer-DSC-Package -Verbose

# create and boot a Nano Server VM
$VmName = "NanoServerTP4"
$VmMemory = 512MB
$VhdRootPath = Join-Path $workingDirectory "FirstSteps"
$VhdName = 'NanoServerTP4.vhd'
$VhdPath = Join-Path $VhdRootPath $VhdName
$switchName = 'Virtual Switch'
New-VM –Name $VmName –MemoryStartupBytes $VmMemory –VHDPath $VhdPath -SwitchName $switchName -Verbose
Start-VM -Name $VmName -Verbose

# retrieve the IP address of the Nano server VM
$VmIpAddresses = Get-VM -Name $VmName | select -ExpandProperty networkadapters | select ipaddresses
$ip = $VmIpAddresses.IPAddresses[0]
$ip
 
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
Get-Command -Module PSDesiredStateConfiguration
Get-Command
Get-Command | measure

# exit session
Exit-PSSession

# show file copy through PS session
Copy-Item -FromSession $ns -Path 'C:\Users\Administrator\Documents\temp\NanoServerRocks.ps1' -Destination $workingDirectory

# apply configuration
Start-DscConfiguration -Path '.\configuration' -Wait -Verbose

#close session
Remove-PSSession -Session $ns


# alternatively you may run commands remotely
Invoke-Command -ComputerName $ip -Credential $user -ScriptBlock {Get-Culture}


Stop-VM -Name $VmName -Verbose