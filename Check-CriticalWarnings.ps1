# Check the event logs for critical warnings

# Define the event log parameters
$logParams = @{
    LogName   = "System"
    EntryType = "Warning"
    ComputerName = "localhost"
}

# Get events related to critical warnings (EventID 41 and 6008)
$events1 = Get-EventLog @logParams | Where-Object { $_.EventID -eq 41 -or $_.EventID -eq 6008 }

# Get events related to specific warnings (EventID 10016 and 10400)
$events2 = Get-EventLog @logParams | Where-Object { $_.EventID -eq 10016 -or $_.EventID -eq 10400 }

# Display the results
Write-Host "Events related to critical warnings (EventID 41 and 6008):"
$events1 | Select-Object TimeGenerated, Source, Message | Format-Table

Write-Host "Events related to specific warnings (EventID 10016 and 10400):"
$events2 | Select-Object TimeGenerated, Source, Message | Format-Table
