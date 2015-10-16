
$nanoComputerName = 'NewNano'

# enter the path where the Windows Server Technical Preview ISO has been mounted
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

# to add drivers
#New-NanoServerImage -MediaPath \\Path\To\Media\en_us -BasePath .\Base -TargetPath .\InjectingDrivers -DriversPath .\Extra\Drivers

# to enable  Powershell remoting, add the IP address of the Nano Server to the trusted hosts list
# from an elevated command line
# winrm set winrm/config/client @{TrustedHosts="192.168.1.4"}
# this method through Powershell did not work for me
$ip = “192.168.1.10”
Enable-PSRemoting -SkipNetworkProfileCheck -Force
Get-Item wsman:\localhost\Client\TrustedHosts
Set-Item WSMan:\localhost\Client\TrustedHosts $ip -Concatenate -Force
#Set-Item WSMan:\localhost\Client\TrustedHosts -Value "192.168.1.4" -Force

# create and boot Nano Server VM TODO

# first session on Nano Server through Powershell remoting
$user = “$ip\Administrator”
Enter-PSSession -ComputerName $ip -Credential $user
# do some work
Exit-PSSession

# run commands remotely
Invoke-Command -ComputerName $ip -Credential $user -ScriptBlock {Get-Culture}
Invoke-Command -ComputerName $ip -Credential $user -ScriptBlock {Stop-Computer -Force}

# try to download file from Internet TODO