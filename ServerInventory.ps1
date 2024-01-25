# Import the Active Directory module
Import-Module ActiveDirectory

# Prompt for credentials
$Cred = Get-Credential

# Get list of servers from file
$Servers = Get-Content C:\Temp\ServerList.txt

# Loop through servers and check if they are online
ForEach ($Server in $Servers)
{
    # Check if the server is online
    if (Test-Connection -ComputerName $Server -Count 1 -Quiet)
    {
        Write-Host "Connecting to $Server..." -ForegroundColor Green

        # Connect to the remote server
        $Session = New-PSSession -ComputerName $Server -Credential $Cred

        # Load the remote server into the current session
        Invoke-Command -Session $Session -ScriptBlock {
            # Get CPU Information
            $CPUInfo = Get-WmiObject Win32_Processor
            # Get OS Information
            $OSInfo = Get-WmiObject Win32_OperatingSystem
            # Get Memory Information
            $PhysicalMemory = Get-WmiObject CIM_PhysicalMemory | Measure-Object -Property capacity -Sum | % { [math]::round(($_.sum / 1GB), 2) }
            # Get Network Configuration
            $Network = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter 'ipenabled = "true"'
            # Get local admins
            $localadmins = Get-CimInstance -ClassName Win32_GroupUser | Where-Object { $_.GroupComponent -match 'Administrators' } | ForEach-Object { $_.PartComponent -match 'Name\s*=\s*"(.+)"' | Out-Null; $matches[1] }
            # Get list of shares
            $Shares = Get-WmiObject Win32_share | Where-Object { $_.name -NotLike "*$" }

            $infoObject = New-Object PSObject
            # Add data to the infoObjects.
            Add-Member -inputObject $infoObject -memberType NoteProperty -name "ServerName" -value $CPUInfo.SystemName
            Add-Member -inputObject $infoObject -memberType NoteProperty -name "CPU_Name" -value $CPUInfo.Name
            Add-Member -inputObject $infoObject -memberType NoteProperty -name "TotalMemory_GB" -value $PhysicalMemory
            Add-Member -inputObject $infoObject -memberType NoteProperty -name "OS_Name" -value $OSInfo.Caption
            Add-Member -inputObject $infoObject -memberType NoteProperty -name "OS_Version" -value $OSInfo.Version
            Add-Member -inputObject $infoObject -memberType NoteProperty -name "IP Address" -value $Network.IPAddress
            Add-Member -inputObject $infoObject -memberType NoteProperty -name "LocalAdmins" -value $localadmins
            Add-Member -inputObject $infoObject -memberType NoteProperty -name "SharesName" -value $Shares.Name
            Add-Member -inputObject $infoObject -memberType NoteProperty -name "SharesPath" -value $Shares.Path

            $infoObject
        } | Select-Object * -ExcludeProperty PSComputerName, RunspaceId, PSShowComputerName | Export-Csv -path "C:\Temp\Server_Inventory_$((Get-Date).ToString('MM-dd-yyyy')).csv" -NoTypeInformation

        # Log the activity
        Write-Host "Connected to $Server and collected information..." -ForegroundColor Green

        # End the session
        Remove-PSSession $Session
    }
    else
    {
        Write-Host "Server $Server is not online. Skipping..." -ForegroundColor Red
    }
}

# Catch any errors
Catch
{
    Write-Host "An error occurred: $($Error[0])" -ForegroundColor Red
}

# End the script
Write-Host "Script complete." -ForegroundColor Green
