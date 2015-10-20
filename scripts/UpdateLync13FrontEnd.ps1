# script skeleton to update a Lync 2013 Front End server

Import-Module Lync

# address to download Lync Update Installer
# http://www.microsoft.com/en-us/download/details.aspx?id=36820
# address to download SQL Server CU
# http://hotfixv4.microsoft.com/SQL%202012/sp2/ql11Sp2Cu8x64/11.0.5634.1/free/487325_intl_x64_zip.exe

$computerName = 'FE01.contoso.com'
$remotePath = '\\share\lync\patching'
$fileName = 'LyncServerUpdateInstaller.exe'
$localDirectory = 'lync-patch-october-2015'
$localPath = 'C:\temp'

# Step 1: verify that the FE pool is ready to be updated
# N.B. this command must be run locally on a Front End server in the pool , cannot be run remotely
Get-CSPoolUpgradeReadinessState

# Step 2: stop Lync services on one of the FE server
Stop-CSWindowsService -Graceful

# Step 3: check that Lync services are stopped and that no more connections are active on the FE server 
Get-CSWindowsService

# Step 4: run the Cumulative Update installer
# we copy the  installer from a shared folder to the FE server
$LyncInstallerRemote = Join-Path $remotePath $fileName
$localInstallerPath = Join-Path $localPath $localDirectory
if ( -not (Test-Path $localInstallerPath) ) {
    New-Item -Path $localPath -ItemType Directory -Name $localDirectory
}
Copy-Item $LyncInstallerRemote -Destination $localInstallerPath
$localLyncInstaller = Join-Path $localInstallerPath $fileName
# run the Cumulative Update installer
# /silentmode /forcereboot
$localLyncInstaller

# Step 5: disable automatic restart of Lync services on system reboot
Get-CSWindowsService | Set-Service -StartupType 'Disabled'

# Step 6: apply Windows Update and SQL server update
#$SqlServerUpdatePath = 'C:\temp'
#$SqlServerUpdateName = 'SQLEXPR_x64_ENU.exe'
#$SqlServerUpdateInstaller = Join-Path $SqlServerUpdatePath $SqlServerUpdateName
#$SqlServerUpdateInstaller /ACTION=Patch /allinstances /IAcceptSQLServerLicenseTerms
#.\SQLEXPR_x64_ENU.exe /ACTION=Patch /allinstances /IAcceptSQLServerLicenseTerms

# Step 7: re-enable automatic startup of Lync services on system start
Get-CSWindowsService | Set-Service -StartupType 'Automatic'

# Step 8: restart all Lync services
Get-CSWindowsService | Start-Service