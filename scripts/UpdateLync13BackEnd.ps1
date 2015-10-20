# script skeleton to update a Lync 2013 Back End server

Import-Module Lync

# address to download SQL Server CU
# http://hotfixv4.microsoft.com/SQL%202012/sp2/ql11Sp2Cu8x64/11.0.5634.1/free/487325_intl_x64_zip.exe

$principalServer = 'BE01.contoso.com'
$mirrorServer = 'BE02.contoso.com'
$poolFqdn = 'BE.contoso.com'
$SqlServerUpdatePath = 'C:\temp'
$SqlServerUpdateName = '487325_intl_x64_zip.exe'
$SqlServerUpdateInstaller = Join-Path $SqlServerUpdatePath $SqlServerUpdateName

Test-CSDatabase -ConfiguredDatabases -SQLServerFQDN $principalServer

# Make sure App,User and CentralMgmt are active on Principal server (BE01.contoso.com)
#Get-CSDatabaseMirrorState
Get-CsDatabaseMirrorState -PoolFqdn $poolFqdn -DatabaseType Application
Get-CsDatabaseMirrorState -PoolFqdn $poolFqdn -DatabaseType User
Get-CsDatabaseMirrorState -PoolFqdn $poolFqdn -DatabaseType CentralMgmt

# Update Lync Back-End Database on Principal server (BE01.contoso.com)
Install-CSDatabase -ConfigurationDatabases -SqlServerFQDN $principalServer -Verbose

# Install Windows and SQL Updates on Mirror server (BE02.contoso.com)
# apply SQL server update
$SqlServerUpdateInstaller /ACTION=Patch /allinstances /IAcceptSQLServerLicenseTerms

# Perform a Database Switchover to activate Mirror server (BE02.contoso.com) 
Invoke-CsDatabaseFailover -PoolFqdn $poolFqdn -DatabaseType Application -NewPrincipal mirror -Verbose
Invoke-CsDatabaseFailover -PoolFqdn $poolFqdn -DatabaseType User -NewPrincipal mirror -Verbose
Invoke-CsDatabaseFailover -PoolFqdn $poolFqdn -DatabaseType CentralMgmt -NewPrincipal mirror -Verbose
# Make sure App,User and CentralMgmt are active on server BE02.contoso.com
Get-CsDatabaseMirrorState -PoolFqdn $poolFqdn -DatabaseType Application
Get-CsDatabaseMirrorState -PoolFqdn $poolFqdn -DatabaseType User
Get-CsDatabaseMirrorState -PoolFqdn $poolFqdn -DatabaseType CentralMgmt


# Install Windows and SQL Updates on Principal server (BE01.contoso.com)
# apply SQL server update
$SqlServerUpdateInstaller /ACTION=Patch /allinstances /IAcceptSQLServerLicenseTerms


# Perform a Database Switchback to the Principal server (BE01.contoso.com)
Invoke-CsDatabaseFailover -PoolFqdn $poolFqdn -DatabaseType Application -NewPrincipal principal -Verbose
Invoke-CsDatabaseFailover -PoolFqdn $poolFqdn -DatabaseType User -NewPrincipal principal -Verbose
Invoke-CsDatabaseFailover -PoolFqdn $poolFqdn -DatabaseType CentralMgmt -NewPrincipal principal -Verbose

Test-CSDatabase -ConfiguredDatabases -SQLServerFQDN $principalServer