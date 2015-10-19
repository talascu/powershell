# script skeleton to update a Lync 2013 Back End server

Import-Module Lync

# address to download Lync Update Installer
# http://www.microsoft.com/en-us/download/details.aspx?id=36820

$principalServer = 'BE01.contoso.com'
$mirrorServer = 'BE02.contoso.com'
$poolFqdn = 'BE.contoso.com'
$remotePath = '\\share\lync\patching'
$fileName = 'LyncServerUpdateInstaller.exe'
$localDirectory = 'lync-patch-october-2015'
$localPath = 'C:\temp'

Test-CSDatabase -ConfiguredDatabases -SQLServerFQDN $principalServer

# Make sure App,User and CentralMgmt are active on Principal server (BE01.contoso.com)
#Get-CSDatabaseMirrorState
Get-CsDatabaseMirrorState -PoolFqdn $poolFqdn -DatabaseType Application
Get-CsDatabaseMirrorState -PoolFqdn $poolFqdn -DatabaseType User
Get-CsDatabaseMirrorState -PoolFqdn $poolFqdn -DatabaseType CentralMgmt

# Update Lync Bak-End Database on Principal server (BE01.contoso.com)
Install-CSDatabase -ConfigurationDatabases -SqlServerFQDN $principalServer

# Install Windows and SQL Updates on Mirror server (BE02.contoso.com)

# Perform a Database Switchover to activate Mirror server (BE02.contoso.com) 
Invoke-CsDatabaseFailover -PoolFqdn $poolFqdn -DatabaseType Application -NewPrincipal mirror -Verbose
Invoke-CsDatabaseFailover -PoolFqdn $poolFqdn -DatabaseType User -NewPrincipal mirror -Verbose
Invoke-CsDatabaseFailover -PoolFqdn $poolFqdn -DatabaseType CentralMgmt -NewPrincipal mirror -Verbose

Get-CsDatabaseMirrorState -PoolFqdn $poolFqdn -DatabaseType Application
Get-CsDatabaseMirrorState -PoolFqdn $poolFqdn -DatabaseType User
Get-CsDatabaseMirrorState -PoolFqdn $poolFqdn -DatabaseType CentralMgmt


# Install Windows and SQL Updates on Principal server (BE01.contoso.com)

# Perform a Database Switchback to the Principal server (BE01.contoso.com)
Invoke-CsDatabaseFailover -PoolFqdn $poolFqdn -DatabaseType Application -NewPrincipal principal -Verbose
Invoke-CsDatabaseFailover -PoolFqdn $poolFqdn -DatabaseType User -NewPrincipal principal -Verbose
Invoke-CsDatabaseFailover -PoolFqdn $poolFqdn -DatabaseType CentralMgmt -NewPrincipal principal -Verbose

Test-CSDatabase -ConfiguredDatabases -SQLServerFQDN $principalServer