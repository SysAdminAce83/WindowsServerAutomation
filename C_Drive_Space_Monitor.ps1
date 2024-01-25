# Define the drive letter to monitor
$DriveLetter = "C"

# Define the threshold for low disk space in percentage
$Threshold = 10

# Define the email settings
$SMTPServer = "smtp.example.com"
$FromAddress = "diskalerts@example.com"
$ToAddress = "admin@example.com"
$Subject = "Low disk space alert for drive $DriveLetter"

# Define the TreeSize Free settings
$TreeSizePath = "C:\Temp\TreeSizeFree\TreeSizeFree.exe"
$ReportFolderPath = "C:\Temp\TreeSizeFree"
$ReportPath = Join-Path $ReportFolderPath "Report.xlsx"
$TopCount = 10

# Get the current available disk space
$Drive = Get-Volume -DriveLetter $DriveLetter
$FreeSpacePercentage = [Math]::Round(($Drive.SizeRemaining / $Drive.Size) * 100, 2)

# Check if the available space is below the threshold
if ($FreeSpacePercentage -le $Threshold) {
    # Run TreeSize Free silently and generate the report
    $Arguments = "/scan $DriveLetter /export $ReportPath /sort size_desc /top $TopCount /close"
    Start-Process -FilePath $TreeSizePath -ArgumentList $Arguments -WindowStyle Hidden -Wait

    # Send an email alert with the report attached
    $Body = "The available disk space on drive $DriveLetter is currently $FreeSpacePercentage%, which is below or equal to the threshold of $Threshold%. Here is the report for the top $TopCount highest space-consuming folders:"
    Send-MailMessage -From $FromAddress -To $ToAddress -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Attachments $ReportPath -Credential (Get-Credential)

    # Delete the report file
    Remove-Item -Path $ReportPath -Force
}
