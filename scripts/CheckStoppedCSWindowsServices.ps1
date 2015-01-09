
# The Signal-StoppedCSWindowsServices function in this script can be used when performing maintenance on 
# a Lync Front End server and you need to ensure that there is no active communication 
# (i.e. all CsWindowsService services are stopped).
# It checks at fixed time if all services are stopped and it prints out to the screen a message,
# stating the result of the check.
# Strategy: Count periodically the number of stopped services and checks it against the total number of 
# CsWindowsService services. 
# N.B. in order to use the Signal-StoppedCSWindowsServices function "dot sourcing" is needed. This is 
# achieved by typing . .\CheckStoppedCSWindowsServices.ps1 

<#
.Synopsis
   Check periodically if all CSWindowsService services are in Stopped state, which means no more active conferences.
   The function checks at fixed time if all services are stopped and it prints out to the screen a message,
   stating the result of the check. 
   You can specify the number of checks per hour and the total number of hours. 
   Default values are 6 checks per hour (one every 10 minutes) for 3 hours.

   Function: Signal-StoppedCSWindowsServices
   Author: Tudor A. Lascu
   Required Dependencies: None
   Optional Dependencies: None
   Version: 1.0

.DESCRIPTION
   This function can be used when performing maintenance on a Lync Front End server and you need to 
   ensure that there is no active communication (i.e. all CsWindowsService services are stopped).
   The function retrieves the total number of CsWindowsService services and periodically performs a check against 
   the total number of stopped services. If they are equal (i.e. all CsWindowsService services are stopped) 
   it prints a success message on the screen.
    
.EXAMPLE
   Signal-StoppedCSWindowsServices -ChecksPerHour 6
   This example shows how to specify the number of checks per hour.

.EXAMPLE
   Signal-StoppedCSWindowsServices -Hours 4
   This example shows how to specify the total number hours for which you want to keep checking.

.EXAMPLE
   Signal-StoppedCSWindowsServices -ChecksPerHour 6 -Hours 4
   This example shows how to specify the number of checks per hour and the total number hours for 
   which you want to keep checking.

.NOTES
Github repo: https://github.com/talascu/powerShell

#>
Function Signal-StoppedCSWindowsServices{
    [CmdletBinding()]
    Param
    (
        # how many checks per hour
        [Int32]$ChecksPerHour = 6,
        # for how many hours to go on
        [Int32]$Hours = 3
        #[int]$numServices = 18
    )
    Begin 
    {
        # number of seconds to sleep
        $Delay = 3600 / $ChecksPerHour
        # count the total number of CsWindowsService services
        #$WindowsServices = Get-Service | measure
        $WindowsServices = Get-CsWindowsService | measure
        $NumServices = $WindowsServices.Count
    }
    Process
    {
        # total number of iterations
        $Iterations = $ChecksPerHour * $Hours

        $i = 1
        Do  {
            Start-Sleep -s $Delay
            $CurrentTime = Get-Date -Format g
            Write-Host "`n$CurrentTime Check"
            #$StoppedService = Get-Service | Where-Object {$_.Status -eq "Stopped"} | measure
            $StoppedService = Get-CsWindowsService | Where-Object {$_.Status -eq "Stopped"} | measure
            $StoppedServiceCount = $StoppedService.Count
            If ($StoppedServiceCount -eq $NumServices) { 
                Write-Host "--------------------------> NO MORE ACTIVE COMMUNICATIONS!" 
            } Else { 
                $NumActiveServices = $NumServices - $StoppedServiceCount 
                Write-Host "ACTIVE COMMUNICATIONS: still $NumActiveServices active services" 
            }
            $i++
        }
        Until ($i -eq $Iterations)
    }
    End 
    {
    }

}
