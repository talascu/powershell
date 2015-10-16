



# download necessary scripts, see 
# http://blogs.technet.com/b/nanoserver/archive/2015/06/16/powershell-script-to-build-your-nano-server-image.aspx
$ConvertWindowsImageScript = 'https://gallery.technet.microsoft.com/scriptcenter/Convert-WindowsImageps1-0fe23a8f/file/59237/7/Convert-WindowsImage.ps1'
$NanoServerScript = 'http://blogs.technet.com/cfs-filesystemfile.ashx/__key/telligent-evolution-components-attachments/01-10474-00-00-03-65-09-88/NanoServer.ps1'
$ConvertWindowsImageScriptDest = Join-Path $destination 'Convert-WindowsImage.ps1'
$NanoServerScriptDest = Join-Path $destination 'NanoServer.ps1'
Invoke-WebRequest $ConvertWindowsImageScript -OutFile $ConvertWindowsImageScriptDest
Invoke-WebRequest $NanoServerScript -OutFile $NanoServerScriptDest


# avoid digital signature check only for current session
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# in NanoServer.ps1 script replace line and save it as  a new file MyNanoServer.ps1
# [String]$Language = [System.Globalization.CultureInfo]::CurrentCulture.Name.ToLower(),
# with line     
# [String]$Language = "en-us",
(Get-Content .\NanoServer.ps1).replace('[System.Globalization.CultureInfo]::CurrentCulture.Name.ToLower()', '"en-us"') | Set-Content .\MyNanoServer.ps1

# dot source the modified NanoServer.ps1 script, MyNanoServer.ps1
. .\MyNanoServer.ps1

New-NanoServerImage -MediaPath F:\ -BasePath .\Base -TargetPath .\FirstSteps -ComputerName FirstStepsNano -GuestDrivers -EnableIPDisplayOnBoot

# to add drivers
#New-NanoServerImage -MediaPath \\Path\To\Media\en_us -BasePath .\Base -TargetPath .\InjectingDrivers -DriversPath .\Extra\Drivers

# to enable  Powershell remoting, add the IP address of the Nano Server to the trusted hosts list
# from an elevated command line
# winrm set winrm/config/client @{TrustedHosts="192.168.1.4"}
# this method through Powershell did not work for me
Enable-PSRemoting -SkipNetworkProfileCheck -Force
Get-Item wsman:\localhost\Client\TrustedHosts
Set-Item WSMan:\localhost\Client\TrustedHosts 192.168.1.4
#Set-Item WSMan:\localhost\Client\TrustedHosts -Value "192.168.1.4" -Force

# first session on Nano Server through Powershell remoting
$ip = “192.168.1.4”
$user = “$ip\Administrator”
Enter-PSSession -ComputerName $ip -Credential $user
# do some work
Exit-PSSession

# run commands remotely
Invoke-Command -ComputerName $ip -Credential $user -ScriptBlock {Get-Culture}
Invoke-Command -ComputerName $ip -Credential $user -ScriptBlock {Stop-Computer -Force}

# try to download file from Internet TODO