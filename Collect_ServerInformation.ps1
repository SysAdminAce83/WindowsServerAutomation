<#
.SYNOPSIS
  Name: Get-SysInfo.ps1
  The purpose of this script is to retrieve information of remote systems.
.DESCRIPTION
  This is a simple script with UI to retrieve information of remote system regarding the hardware,
  software and peripherals.
  It will gather hardware specifications, peripherals, installed software, running processes, services
  and Operating System through a very simple and functioning GUI. You can also perform Ping Test, NetStat,
  Remote Desktop and export the resutls in a text file or email the results. You are able to get the
  information from two remote systems at the same time and compare outcome.
.RELATED LINKS
  
Home

.NOTES
  Version:      1.5
  Updated:      23-08-2018        - Added ability to retrieve information from 2 computers
                                  - Added comparison of results
                                  - Code improvements and optimization
                                  - Added basic error control
                                  - Remove filtering of information
                                  - UI Improvements
  Updated:      13-03-2018        - Added ability to email results as attachment
                                  - Added date and time for the results
                                  - Updated description
  Updated:      02-03-2018        - Added ability to export result in text file
                                  - Added TCP Connection information
                                  - Added Title for each information retrieval
  Updated:      25-02-2018        - Added Fan Information
                                  - Added Battery Information
                                  - Added Portable Battery Information
                                  - Added Network Settings Information
                                  - Added ping connection test of remote system
                                  - Added Remote Desktop connection to the machine.
                                  - Warning for the use of Win32_Product class
                                  - Added option for Win32Reg_AddRemovePrograms class
                                  - Added visibility to Taskbar
                                  - Added Help information
  Release Date: 22-02-2018
  Author: Stephanos Constantinou
.EXAMPLE
  Run the Get-SysInfo script to retrieve the information.
  Get-SysInfo.ps1
#>
$ErrorActionPreference = "Stop"
$ErrorMessage = @"
There was an error while trying to retrieve the information.
It might be one of the below cases:
 - Computer/Server is not reachable
 - Computer/Server turned off
 - Computer/Server name is not correct
 - You do not have permissions
"@
function Get-NetStat {
    $CompareText = $btn_Compare.Text
    $lbl_compareinfo.Text = ""
    If ($CompareText -eq "Compare"){Get-NetStat1}
    elseif ($CompareText -eq "Single"){Get-NetStat2}}
function Test-Ping {
    $CompareText = $btn_Compare.Text
    $lbl_compareinfo.Text = ""
    If ($CompareText -eq "Compare"){Test-Ping1}
    elseif ($CompareText -eq "Single"){Test-Ping2}}
function Get-Info {
    $CompareText = $btn_Compare.Text
    $lbl_compareinfo.Text = ""
    If ($CompareText -eq "Compare"){Get-Info1}
    elseif ($CompareText -eq "Single"){Get-Info2}}
function Get-Info1 {
    $ComputerName = $txt_ComputerName1.Text
    try{
        $Info = Get-CimInstance -Class $Class -ComputerName $ComputerName -Property *
        $lbl_sysinfo1.ForeColor = "Black"
        $lbl_sysinfo1.Text = $InfoTitle
        $lbl_sysinfo1.Text += $Info |
            Select-Object -Property * |
            Out-String}
    catch{
        $lbl_sysinfo1.ForeColor = "Red"
        $lbl_sysinfo1.Text = $ErrorMessage}}
function Get-Info2 {
    $ComputerName1 = $txt_ComputerName1.Text
    $ComputerName2 = $txt_ComputerName2.Text
    try{
        $Info1 = Get-CimInstance -Class $Class -ComputerName "$ComputerName1" -Property *
        $Info2 = Get-CimInstance -Class $Class -ComputerName "$ComputerName2" -Property *
        $lbl_sysinfo2.ForeColor = "Black"
        $lbl_sysinfo2.Text = $InfoTitle
        $lbl_sysinfo2.Text += $Info1 |
            Select-Object -Property * |
            Out-String
        $lbl_sysinfo3.ForeColor = "Black"
        $lbl_sysinfo3.Text = $InfoTitle
        $lbl_sysinfo3.Text += $Info2 |
            Select-Object -Property * |
            Out-String
         Compare-Computer $Info1 $Info2}
    catch{
        $lbl_sysinfo2.ForeColor = "Red"
        $lbl_sysinfo2.Text = $ErrorMessage
        $lbl_sysinfo3.ForeColor = "Red"
        $lbl_sysinfo3.Text = $ErrorMessage}}
Function Compare-Computer {
    Param(
        [PSObject]$Computer1,
        [PSObject]$Computer2
    )
    $InfoProperties = $Computer1 | Get-Member -MemberType Property,NoteProperty | ForEach-Object Name
    $InfoProperties += $Computer2 | Get-Member -MemberType Property,NoteProperty | ForEach-Object Name
    $InfoProperties = $InfoProperties | Sort-Object | Select-Object -Unique
    $Differences = @()
    foreach ($InfoProperty in $InfoProperties) {
        $Difference = Compare-Object $Computer1 $Computer2 -Property $InfoProperty
        if ($Difference) {
            $DifferencesProperties = @{
                Property=$InfoProperty
                Computer1=($Difference | Where-Object {$_.SideIndicator -eq '<='} | ForEach-Object $($InfoProperty))
                Computer2=($Difference | Where-Object {$_.SideIndicator -eq '=>'} | ForEach-Object $($InfoProperty))
            }
            $Differences += New-Object PSObject -Property $DifferencesProperties
        }
    }
    if ($Differences) {
        $lbl_compareinfo.Text = $Differences |
            Select-Object Property,Computer1,Computer2 |
            Out-String}
    else {$lbl_compareinfo.Text = "There is no difference"}
}
function Test-Ping1 {
    $ComputerName1 = $txt_ComputerName1.Text
    $lbl_compareinfo.Text = ""
    If ($ComputerName1 -eq ""){
        $lbl_sysinfo1.ForeColor = "Red"
        $lbl_sysinfo1.Text = "Please provide a computer name to test the connection"}
    else {
        try{
            $Ping_Test = Test-Connection $ComputerName1
            $lbl_sysinfo1.ForeColor = "Black"
            $lbl_sysinfo1.Text = "Ping Test Information - $(Get-Date)"
            $lbl_sysinfo1.Text += $Ping_Test |
                Out-String}
        catch{$lbl_sysinfo1.Text = $ErrorMessage}}}
function Test-Ping2 {
    $ComputerName1 = $txt_ComputerName1.Text
    $ComputerName2 = $txt_ComputerName2.Text
    $lbl_compareinfo.Text = ""
    switch -Regex ($ComputerName1){
        {($ComputerName1 -eq "") -and ($ComputerName2 -ne "")}{
            $lbl_sysinfo2.ForeColor = "Red"
            $lbl_sysinfo2.Text = "Please provide a computer name to test the connection"
            try{
                $Ping_Test2 = Test-Connection $ComputerName2
                $lbl_sysinfo3.ForeColor = "Black"
                $lbl_sysinfo3.Text = "Ping Test Information - $(Get-Date)"
                $lbl_sysinfo3.Text += $Ping_Test2 |
                    Out-String}
            catch{$lbl_sysinfo3.Text = $ErrorMessage}}
        {($ComputerName1 -ne "") -and ($ComputerName2 -eq "")}{
            $lbl_sysinfo3.ForeColor = "Red"
            $lbl_sysinfo3.Text = "Please provide a computer name to test the connection"
            try{
                $Ping_Test1 = Test-Connection $ComputerName1
                $lbl_sysinfo2.ForeColor = "Black"
                $lbl_sysinfo2.Text = "Ping Test Information - $(Get-Date)"
                $lbl_sysinfo2.Text += $Ping_Test1 |
                    Out-String}
            catch{$lbl_sysinfo2.Text = $ErrorMessage}}
        {($ComputerName1 -eq "") -and ($ComputerName2 -eq "")}{
            $lbl_sysinfo2.ForeColor = "Red"
            $lbl_sysinfo2.Text = "Please provide a computer name to test the connection"
            $lbl_sysinfo3.ForeColor = "Red"
            $lbl_sysinfo3.Text = "Please provide a computer name to test the connection"}
        {($ComputerName1 -ne "") -and ($ComputerName2 -ne "")}{
            $Ping_Test1 = Test-Connection $ComputerName1
            $Ping_Test2 = Test-Connection $ComputerName2
            try{
                $Ping_Test2 = Test-Connection $ComputerName2
                $lbl_sysinfo3.ForeColor = "Black"
                $lbl_sysinfo3.Text = "Ping Test Information - $(Get-Date)"
                $lbl_sysinfo3.Text += $Ping_Test2 |
                    Out-String}
            catch{$lbl_sysinfo3.Text = $ErrorMessage}
            try{
                $Ping_Test1 = Test-Connection $ComputerName1
                $lbl_sysinfo2.ForeColor = "Black"
                $lbl_sysinfo2.Text = "Ping Test Information - $(Get-Date)"
                $lbl_sysinfo2.Text += $Ping_Test1 |
                    Out-String}
            catch{$lbl_sysinfo2.Text = $ErrorMessage}}}}
function Get-NetStat1 {
    $ComputerName1 = $txt_ComputerName1.Text
    $lbl_compareinfo.Text = ""
    if ($ComputerName1 -eq ""){
        try{
            $LocalNetStat = Get-NetTCPConnection
            $lbl_sysinfo1.Text = "NetStat Information - $(Get-Date)"
            $lbl_sysinfo1.Text += $LocalNetStat |
                Format-Table |
                Out-String}
        catch{$lbl_sysinfo1.Text = $ErrorMessage}}
    else{
        try{
            $RemoteNetStat = Invoke-Command -ComputerName $ComputerName1 -ScriptBlock {Get-NetTCPConnection}
            $lbl_sysinfo1.Text = "NetStat Information - $(Get-Date)"
            $lbl_sysinfo1.Text += $RemoteNetStat |
                Format-Table |
                Out-String }
        catch{$lbl_sysinfo1.Text = $ErrorMessage}}}
function Get-NetStat2 {
    $ComputerName1 = $txt_ComputerName1.Text
    $ComputerName2 = $txt_ComputerName2.Text
    $lbl_compareinfo.Text = ""
    switch -Regex ($ComputerName1){
        {($ComputerName1 -eq "") -and ($ComputerName2 -ne "")}{
            try{
                $NetStat1 = Get-NetTCPConnection
                $lbl_sysinfo2.Text = "NetStat Information - $(Get-Date)"
                $lbl_sysinfo2.Text += $NetStat1 |
                    Format-Table |
                    Out-String}
            catch{$lbl_sysinfo2.Text = $ErrorMessage}
            try{
                $NetStat2 = Invoke-Command -ComputerName $ComputerName2 -ScriptBlock {Get-NetTCPConnection}
                $lbl_sysinfo3.Text = "NetStat Information - $(Get-Date)"
                $lbl_sysinfo3.Text += $NetStat2 |
                    Format-Table |
                    Out-String }
            catch{$lbl_sysinfo3.Text = $ErrorMessage}}
        {($ComputerName1 -ne "") -and ($ComputerName2 -eq "")}{
            try{
                $NetStat1 = Invoke-Command -ComputerName $ComputerName1 -ScriptBlock {Get-NetTCPConnection}
                $lbl_sysinfo2.Text = "NetStat Information - $(Get-Date)"
                $lbl_sysinfo2.Text += $NetStat1 |
                    Format-Table |
                    Out-String }
            catch{$lbl_sysinfo2.Text = $ErrorMessage}
            try{
                $NetStat2 = Get-NetTCPConnection
                $lbl_sysinfo3.Text = "NetStat Information - $(Get-Date)"
                $lbl_sysinfo3.Text += $NetStat2 |
                    Format-Table |
                    Out-String}
            catch{$lbl_sysinfo3.Text = $ErrorMessage}
            }
        {($ComputerName1 -eq "") -and ($ComputerName2 -eq "")}{
            try{
                $NetStat1 = Get-NetTCPConnection
                $lbl_sysinfo2.Text = "NetStat Information - $(Get-Date)"
                $lbl_sysinfo2.Text += $NetStat1 |
                    Format-Table |
                    Out-String}
            catch{$lbl_sysinfo2.Text = $ErrorMessage}
            try{
                $NetStat2 = Get-NetTCPConnection
                $lbl_sysinfo3.Text = "NetStat Information - $(Get-Date)"
                $lbl_sysinfo3.Text += $NetStat2 |
                    Format-Table |
                    Out-String}
            catch{$lbl_sysinfo3.Text = $ErrorMessage}}
        {($ComputerName1 -ne "") -and ($ComputerName2 -ne "")}{
            try{
                $NetStat1 = Invoke-Command -ComputerName $ComputerName1 -ScriptBlock {Get-NetTCPConnection}
                $lbl_sysinfo2.Text = "NetStat Information - $(Get-Date)"
                $lbl_sysinfo2.Text += $NetStat1 |
                    Format-Table |
                    Out-String }
            catch{$lbl_sysinfo2.Text = $ErrorMessage}
            try{
                $NetStat2 = Invoke-Command -ComputerName $ComputerName1 -ScriptBlock {Get-NetTCPConnection}
                $lbl_sysinfo3.Text = "NetStat Information - $(Get-Date)"
                $lbl_sysinfo3.Text += $NetStat2 |
                    Format-Table |
                    Out-String }
            catch{$lbl_sysinfo3.Text = $ErrorMessage}}}
    Compare-Computer $NetStat1 $NetStat2}
$Compare = {
    $CompareText = $btn_Compare.Text
    if ($CompareText -eq "Compare"){
        $btn_Compare.Text = "Single"
        $txt_ComputerName1.Text = ""
        $txt_ComputerName2.Text = ""
        $lbl_sysinfo1.Text = ""
        $lbl_sysinfo2.Text = ""
        $lbl_sysinfo3.Text = ""
        $lbl_compareinfo.Text = ""
        $lbl_ComputerName1.Text = "Computer Name 1"
        $pnl_sysinfo1.Controls.Remove($lbl_sysinfo1)
        $MainForm.Controls.Remove($pnl_sysinfo1)
        $MainForm.Controls.Remove($btn_RDP)
        $MainForm.Controls.Remove($btn_Export)
        $MainForm.Controls.Add($lbl_ComputerName2)
        $MainForm.Controls.Add($txt_ComputerName2)
        $MainForm.Controls.Add($pnl_sysinfo2)
        $MainForm.Controls.Add($pnl_sysinfo3)
        $MainForm.Controls.Add($pnl_compareinfo)
        $MainForm.Controls.Add($lbl_differences)
        $pnl_sysinfo2.Controls.Add($lbl_sysinfo2)
        $pnl_sysinfo3.Controls.Add($lbl_sysinfo3)
        $pnl_compareinfo.Controls.Add($lbl_compareinfo)}
    elseif($CompareText -eq "Single"){
        $btn_Compare.Text = "Compare"
        $txt_ComputerName1.Text = ""
        $lbl_sysinfo1.Text = ""
        $lbl_sysinfo2.Text = ""
        $lbl_sysinfo3.Text = ""
        $lbl_compareinfo.Text = ""
        $lbl_ComputerName1.Text = "Computer Name"
        $pnl_sysinfo2.Controls.Remove($lbl_sysinfo2)
        $pnl_sysinfo3.Controls.Remove($lbl_sysinfo3)
        $pnl_compareinfo.Controls.Remove($lbl_compareinfo)
        $MainForm.Controls.Add($btn_RDP)
        $MainForm.Controls.Add($btn_Export)
        $MainForm.Controls.Remove($pnl_sysinfo2)
        $MainForm.Controls.Remove($pnl_sysinfo3)
        $MainForm.Controls.Remove($lbl_ComputerName2)
        $MainForm.Controls.Remove($txt_ComputerName2)
        $MainForm.Controls.Remove($lbl_differences)
        $MainForm.Controls.Add($pnl_sysinfo1)
        $MainForm.Controls.Remove($pnl_compareinfo)
        $pnl_sysinfo1.Controls.Add($lbl_sysinfo1)}
        $MainForm.Refresh()}
$System_info = {
    $Class = "Win32_ComputerSystem"
    $InfoTitle = "System Information - $(Get-Date)"
    Get-Info $Class $InfoTitle}
$bios_info = {
    $Class = "Win32_BIOS"
    $InfoTitle = "BIOS Information - $(Get-Date)"
    Get-Info $Class $InfoTitle}
$CPU_info = {
    $Class = "Win32_Processor"
    $InfoTitle = "CPU Information - $(Get-Date)"
    Get-Info $Class $InfoTitle}
$RAM_info = {
    $Class = "Win32_PhysicalMemory"
    $InfoTitle = "RAM Information - $(Get-Date)"
    Get-Info $Class $InfoTitle}
$MB_info = {
    $Class = "Win32_BaseBoard"
    $InfoTitle = "MotherBoard Information - $(Get-Date)"
    Get-Info $Class $InfoTitle}
$PhysicalDrives_info = {
    $Class = "Win32_DiskDrive"
    $InfoTitle = "Physical Drives Information - $(Get-Date)"
    Get-Info $Class $InfoTitle}
$LogicalDrives_info = {
    $Class = "Win32_LogicalDisk"
    $InfoTitle = "Logical Drives Information - $(Get-Date)"
    Get-Info $Class $InfoTitle}
$GPU_info = {
    $Class = "Win32_VideoController"
    $InfoTitle = "GPU Information - $(Get-Date)"
    Get-Info $Class $InfoTitle}
$Network_info = {
    $Class = "Win32_NetworkAdapter"
    $InfoTitle = "Network Devices Information - $(Get-Date)"
    Get-Info $Class $InfoTitle}
$NetSettings_info = {
    $Class = "Win32_NetworkAdapterConfiguration"
    $InfoTitle = "Network Configuration Information - $(Get-Date)"
    Get-Info $Class $InfoTitle}
$Monitor_info = {
    $Class = "Win32_DesktopMonitor"
    $InfoTitle = "Monitors Information - $(Get-Date)"
    Get-Info $Class $InfoTitle}
$OS_info = {
    $Class = "Win32_OperatingSystem"
    $InfoTitle = "Operating System Information - $(Get-Date)"
    Get-Info $Class $InfoTitle}
$Keyboard_info = {
    $Class = "Win32_Keyboard"
    $InfoTitle = "Keyboard Information - $(Get-Date)"
    Get-Info $Class $InfoTitle}
$Mouse_info = {
    $Class = "Win32_PointingDevice"
    $InfoTitle = "Pointing Device Information - $(Get-Date)"
    Get-Info $Class $InfoTitle}
$CDROM_info = {
    $Class = "Win32_CDROMDrive"
    $InfoTitle = "CD-ROM Drives Information - $(Get-Date)"
    Get-Info $Class $InfoTitle}
$Sound_info = {
    $Class = "Win32_SoundDevice"
    $InfoTitle = "Sound Devices Information - $(Get-Date)"
    Get-Info $Class $InfoTitle}
$Printers_info = {
    $Class = "Win32_Printer"
    $InfoTitle = "Printers Information - $(Get-Date)"
    Get-Info $Class $InfoTitle}
$Fan_info = {
    $Class = "Win32_Fan"
    $InfoTitle = "Fans Information - $(Get-Date)"
    Get-Info $Class $InfoTitle}
$Battery_info = {
    $Class = "Win32_Battery"
    $InfoTitle = "Battery Information - $(Get-Date)"
    Get-Info $Class $InfoTitle}
$PortBattery_info = {
    $Class = "Win32_PortableBattery"
    $InfoTitle = "Portable Battery Information - $(Get-Date)"
    Get-Info $Class $InfoTitle}
$Software_info = {
    $Product = {
        $Warning = [System.Windows.MessageBox]::Show('Are you sure that you want to run this using Win32_Product class?','Warning','YesNo','Error')
        switch ($Warning){
            Yes{
                $SoftwareOption.Close()
                $Class = "Win32Reg_Product"
                $InfoTitle = "Software Information - $(Get-Date)"
                Get-Info $Class $InfoTitle}
            No{Break}
        }
    }
    $AddRemove = {
        $SoftwareOption.Close()
        $Class = "Win32Reg_AddRemovePrograms"
        $InfoTitle = "Software Information - $(Get-Date)"
        Get-Info $Class $InfoTitle}
    $SoftwareOption = New-Object system.Windows.Forms.Form
    $SoftwareOption.Text = "Class Option"
    $SoftwareOption.Size = New-Object System.Drawing.Size(500,130)
    $SoftwareOption.AutoSize = $False
    $SoftwareOption.AutoScroll = $False
    $SoftwareOption.MinimizeBox = $False
    $SoftwareOption.MaximizeBox = $False
    $SoftwareOption.WindowState = "Normal"
    $SoftwareOption.SizeGripStyle = "Hide"
    $SoftwareOption.ShowInTaskbar = $True
    $SoftwareOption.Opacity = 1
    $SoftwareOption.FormBorderStyle = "Fixed3D"
    $SoftwareOption.StartPosition = "CenterScreen"
    $lbl_SoftwareOption = New-Object System.Windows.Forms.Label
    $lbl_SoftwareOption.Location = New-Object System.Drawing.Point(20,10)
    $lbl_SoftwareOption.Size = New-Object System.Drawing.Size(500,25)
    $lbl_SoftwareOption.Text = "Please select the class that you want to use:"
    $lbl_SoftwareOption.Font = $Font
    $SoftwareOption.Controls.Add($lbl_SoftwareOption)
    $btn_Product = New-Object System.Windows.Forms.Button
    $btn_Product.Location = New-Object System.Drawing.Point(10,50)
    $btn_Product.Size = New-Object System.Drawing.Size(230,25)
    $btn_Product.Text = "Win32_Product"
    $btn_Product.Font = $Font
    $btn_Product.Add_Click($Product)
    $SoftwareOption.Controls.Add($btn_Product)
    $btn_AddRemove = New-Object System.Windows.Forms.Button
    $btn_AddRemove.Location = New-Object System.Drawing.Point(250,50)
    $btn_AddRemove.Size = New-Object System.Drawing.Size(230,25)
    $btn_AddRemove.Text = "Win32_AddRemovePrograms"
    $btn_AddRemove.Font = $Font
    $btn_AddRemove.Add_Click($AddRemove)
    $SoftwareOption.Controls.Add($btn_AddRemove)
    $SoftwareOption.ShowDialog()
}
$Process_info = {
    $Class = "Win32_Process"
    $InfoTitle = "Processes Information - $(Get-Date)"
    Get-Info $Class $InfoTitle}
$Services_info = {
    $Class = "Win32_Service"
    $InfoTitle = "Services Information - $(Get-Date)"
    Get-Info $Class $InfoTitle}
$RDP_Connection = {
    $ComputerName1 = $txt_ComputerName1.Text
    mstsc /v:$ComputerName1}
$Export = {
    $ComputerName1 = $txt_ComputerName1.Text
    $TextFile = {
        $ExportOption.Close()
        if ($ComputerName1 -eq ""){
            try{
                $ComputerName1 = (Get-CimInstance -Class Win32_ComputerSystem).Name
                $lbl_sysinfo1.Text |
                    Out-File C:\Scripts\$ComputerName1.txt}
            catch{$lbl_sysinfo1.Text = $ErrorMessage}}}
    $Email = {
        if ($ComputerName1 -eq ""){
            try{
                $ComputerName1 = (Get-CimInstance -Class Win32_ComputerSystem).Name
                $lbl_sysinfo1.Text |
                    Out-File C:\Scripts\$ComputerName1.txt}
            catch{$lbl_sysinfo1.Text = $ErrorMessage}}
        $To  = @(($txt_Recipients.Text) -split ',')
        $Attachement = "C:\Scripts\$ComputerName1.txt"
        $Recipients.Close()
        $EmailCredentials = Get-Credential
        $From = $EmailCredentials.UserName
        $EmailParameters = @{
            To = $To
            Subject = "System Information - $ComputerName1"
            Body = "Please find attached the information that you have requested."
            Attachments = $Attachement
                UseSsl = $True
                Port = "587"
                SmtpServer = "smtp.office365.com"
                Credential = $EmailCredentials
                From = $From}
        Send-MailMessage @EmailParameters}
    $RecipientsDetails = {
        $ExportOption.Close()
        $Recipients = New-Object system.Windows.Forms.Form
        $Recipients.Text = "Recipients"
        $Recipients.Size = New-Object System.Drawing.Size(500,230)
        $Recipients.AutoSize = $False
        $Recipients.AutoScroll = $False
        $Recipients.MinimizeBox = $False
        $Recipients.MaximizeBox = $False
        $Recipients.WindowState = "Normal"
        $Recipients.SizeGripStyle = "Hide"
        $Recipients.ShowInTaskbar = $True
        $Recipients.Opacity = 1
        $Recipients.FormBorderStyle = "Fixed3D"
        $Recipients.StartPosition = "CenterScreen"
        $RecipientsInfo = @"
Please enter the recipient.
If there are multiple recipients, separate recipients with comma (,).
"@
        $lbl_Recipients = New-Object System.Windows.Forms.Label
        $lbl_Recipients.Location = New-Object System.Drawing.Point(0,10)
        $lbl_Recipients.Size = New-Object System.Drawing.Size(500,100)
        $lbl_Recipients.Text = $RecipientsInfo
        $lbl_Recipients.Font = $Font
        $Recipients.Controls.Add($lbl_Recipients)
        $txt_Recipients = New-Object System.Windows.Forms.TextBox
        $txt_Recipients.Location = New-Object System.Drawing.Point(10,120)
        $txt_Recipients.Size = New-Object System.Drawing.Size(460,100)
        $txt_Recipients.Font = $Font
        $Recipients.Controls.Add($txt_Recipients)
        $btn_Recipients = New-Object System.Windows.Forms.Button
        $btn_Recipients.Location = New-Object System.Drawing.Point(180,150)
        $btn_Recipients.Size = New-Object System.Drawing.Size(125,25)
        $btn_Recipients.Text = "OK"
        $btn_Recipients.Font = $Font
        $btn_Recipients.Add_Click($Email)
        $Recipients.Controls.Add($btn_Recipients)
        $Recipients.ShowDialog()}
    $ExportOption = New-Object system.Windows.Forms.Form
    $ExportOption.Text = "Export Method"
    $ExportOption.Size = New-Object System.Drawing.Size(500,130)
    $ExportOption.AutoSize = $False
    $ExportOption.AutoScroll = $False
    $ExportOption.MinimizeBox = $False
    $ExportOption.MaximizeBox = $False
    $ExportOption.WindowState = "Normal"
    $ExportOption.SizeGripStyle = "Hide"
    $ExportOption.ShowInTaskbar = $True
    $ExportOption.Opacity = 1
    $ExportOption.FormBorderStyle = "Fixed3D"
    $ExportOption.StartPosition = "CenterScreen"
    $lbl_ExportOption = New-Object System.Windows.Forms.Label
    $lbl_ExportOption.Location = New-Object System.Drawing.Point(20,10)
    $lbl_ExportOption.Size = New-Object System.Drawing.Size(500,25)
    $lbl_ExportOption.Text = "Please select how you want to export the results:"
    $lbl_ExportOption.Font = $Font
    $ExportOption.Controls.Add($lbl_ExportOption)
    $btn_TextFile = New-Object System.Windows.Forms.Button
    $btn_TextFile.Location = New-Object System.Drawing.Point(10,50)
    $btn_TextFile.Size = New-Object System.Drawing.Size(230,25)
    $btn_TextFile.Text = "Text File"
    $btn_TextFile.Font = $Font
    $btn_TextFile.Add_Click($TextFile)
    $ExportOption.Controls.Add($btn_TextFile)
    $btn_Email = New-Object System.Windows.Forms.Button
    $btn_Email.Location = New-Object System.Drawing.Point(250,50)
    $btn_Email.Size = New-Object System.Drawing.Size(230,25)
    $btn_Email.Text = "Email"
    $btn_Email.Font = $Font
    $btn_Email.Add_Click($RecipientsDetails)
    $ExportOption.Controls.Add($btn_Email)
    $ExportOption.ShowDialog()}
Add-Type -AssemblyName System.Windows.Forms
$Font = New-Object System.Drawing.Font("Consolas",12,[System.Drawing.FontStyle]::Regular)
$MainForm = New-Object system.Windows.Forms.Form
$MainForm.Text = "Computer Information"
$MainForm.Size = New-Object System.Drawing.Size(1200,800)
$MainForm.AutoScroll = $False
$MainForm.AutoSize = $False
$MainForm.FormBorderStyle = "FixedSingle"
$MainForm.MinimizeBox = $True
$MainForm.MaximizeBox = $False
$MainForm.WindowState = "Normal"
$MainForm.SizeGripStyle = "Hide"
$MainForm.ShowInTaskbar = $True
$MainForm.Opacity = 1
$MainForm.StartPosition = "CenterScreen"
$MainForm.ShowInTaskbar = $True
$MainForm.Font = $Font
$btn_Compare = New-Object System.Windows.Forms.Button
$btn_Compare.Location = New-Object System.Drawing.Point(1035,5)
$btn_Compare.Size = New-Object System.Drawing.Size (145,25)
$btn_Compare.Font = $Font
$btn_Compare.Text = "Compare"
$btn_Compare.Add_Click($Compare)
$MainForm.Controls.Add($btn_Compare)
$lbl_ComputerName1 = New-Object System.Windows.Forms.Label
$lbl_ComputerName1.Location = New-Object System.Drawing.Point(155,5)
$lbl_ComputerName1.Size = New-Object System.Drawing.Size(150,25)
$lbl_ComputerName1.Font = $Font
$lbl_ComputerName1.Text = "Computer Name"
$MainForm.Controls.Add($lbl_ComputerName1)
$txt_ComputerName1 = New-Object System.Windows.Forms.TextBox
$txt_ComputerName1.Location = New-Object System.Drawing.Point(305,5)
$txt_ComputerName1.Size = New-Object System.Drawing.Size(200,20)
$txt_ComputerName1.Font = $Font
$MainForm.Controls.Add($txt_ComputerName1)
$lbl_ComputerName2 = New-Object System.Windows.Forms.Label
$lbl_ComputerName2.Location = New-Object System.Drawing.Point(665,5)
$lbl_ComputerName2.Size = New-Object System.Drawing.Size(150,25)
$lbl_ComputerName2.Font = $Font
$lbl_ComputerName2.Text = "Computer Name 2"
$txt_ComputerName2 = New-Object System.Windows.Forms.TextBox
$txt_ComputerName2.Location = New-Object System.Drawing.Point(815,5)
$txt_ComputerName2.Size = New-Object System.Drawing.Size(200,20)
$txt_ComputerName2.Font = $Font
$pnl_sysinfo1 = New-Object System.Windows.Forms.Panel
$pnl_sysinfo1.Location = New-Object System.Drawing.Point(155,45)
$pnl_sysinfo1.Size = New-Object System.Drawing.Size(1020,700)
$pnl_sysinfo1.BorderStyle = "Fixed3D"
$pnl_sysinfo1.AutoSize = $False
$pnl_sysinfo1.AutoScroll = $True
$pnl_sysinfo1.Font = $Font
$pnl_sysinfo1.Text = ""
$MainForm.Controls.Add($pnl_sysinfo1)
$lbl_sysinfo1 = New-Object System.Windows.Forms.Label
$lbl_sysinfo1.Location = New-Object System.Drawing.Point(5,5)
$lbl_sysinfo1.Size = New-Object System.Drawing.Size(490,490)
$lbl_sysinfo1.AutoSize = $True
$lbl_sysinfo1.Font = $Font
$lbl_sysinfo1.Text = ""
$pnl_sysinfo1.Controls.Add($lbl_sysinfo1)
$pnl_sysinfo2 = New-Object System.Windows.Forms.Panel
$pnl_sysinfo2.Location = New-Object System.Drawing.Point(155,45)
$pnl_sysinfo2.Size = New-Object System.Drawing.Size(510,400)
$pnl_sysinfo2.BorderStyle = "Fixed3D"
$pnl_sysinfo2.AutoSize = $False
$pnl_sysinfo2.AutoScroll = $True
$pnl_sysinfo2.Font = $Font
$pnl_sysinfo2.Text = ""
$lbl_sysinfo2 = New-Object System.Windows.Forms.Label
$lbl_sysinfo2.Location = New-Object System.Drawing.Point(5,5)
$lbl_sysinfo2.Size = New-Object System.Drawing.Size(490,490)
$lbl_sysinfo2.AutoSize = $True
$lbl_sysinfo2.Font = $Font
$lbl_sysinfo2.Text = ""
$pnl_sysinfo3 = New-Object System.Windows.Forms.Panel
$pnl_sysinfo3.Location = New-Object System.Drawing.Point(665,45)
$pnl_sysinfo3.Size = New-Object System.Drawing.Size(510,400)
$pnl_sysinfo3.BorderStyle = "Fixed3D"
$pnl_sysinfo3.AutoSize = $False
$pnl_sysinfo3.AutoScroll = $True
$pnl_sysinfo3.Font = $Font
$pnl_sysinfo3.Text = ""
$lbl_sysinfo3 = New-Object System.Windows.Forms.Label
$lbl_sysinfo3.Location = New-Object System.Drawing.Point(5,5)
$lbl_sysinfo3.Size = New-Object System.Drawing.Size(490,490)
$lbl_sysinfo3.AutoSize = $True
$lbl_sysinfo3.Font = $Font
$lbl_sysinfo3.Text = ""
$lbl_differences = New-Object System.Windows.Forms.Label
$lbl_differences.Location = New-Object System.Drawing.Point(610,450)
$lbl_differences.Size = New-Object System.Drawing.Size(110,20)
$lbl_differences.Font = $Font
$lbl_differences.Text = "Differences"
$pnl_compareinfo = New-Object System.Windows.Forms.Panel
$pnl_compareinfo.Location = New-Object System.Drawing.Point(155,470)
$pnl_compareinfo.Size = New-Object System.Drawing.Size(1020,280)
$pnl_compareinfo.BorderStyle = "Fixed3D"
$pnl_compareinfo.AutoSize = $False
$pnl_compareinfo.AutoScroll = $True
$pnl_compareinfo.Font = $Font
$pnl_compareinfo.Text = ""
$lbl_compareinfo = New-Object System.Windows.Forms.Label
$lbl_compareinfo.Location = New-Object System.Drawing.Point(5,5)
$lbl_compareinfo.Size = New-Object System.Drawing.Size(100,100)
$lbl_compareinfo.AutoSize = $True
$lbl_compareinfo.Font = $Font
$lbl_compareinfo.Text = ""
$btn_System = New-Object System.Windows.Forms.Button
$btn_System.Location = New-Object System.Drawing.Point(5,50)
$btn_System.Size = New-Object System.Drawing.Size(145,25)
$btn_System.Font = $Font
$btn_System.Text = "System"
$btn_System.Add_Click($System_info)
$MainForm.Controls.Add($btn_System)
$btn_BIOS = New-Object System.Windows.Forms.Button
$btn_BIOS.Location = New-Object System.Drawing.Point(5,75)
$btn_BIOS.Size = New-Object System.Drawing.Size(145,25)
$btn_BIOS.Font = $Font
$btn_BIOS.Text = "BIOS"
$btn_BIOS.Add_Click($bios_info)
$MainForm.Controls.Add($btn_BIOS)
$btn_CPU = New-Object System.Windows.Forms.Button
$btn_CPU.Location = New-Object System.Drawing.Point(5,100)
$btn_CPU.Size = New-Object System.Drawing.Size(145,25)
$btn_CPU.Font = $Font
$btn_CPU.Text = "CPU"
$btn_CPU.Add_Click($cpu_info)
$MainForm.Controls.Add($btn_CPU)
$btn_RAM = New-Object System.Windows.Forms.Button
$btn_RAM.Location = New-Object System.Drawing.Point(5,125)
$btn_RAM.Size = New-Object System.Drawing.Size(145,25)
$btn_RAM.Font = $Font
$btn_RAM.Text = "RAM"
$btn_RAM.Add_Click($ram_info)
$MainForm.Controls.Add($btn_RAM)
$btn_MB = New-Object System.Windows.Forms.Button
$btn_MB.Location = New-Object System.Drawing.Point(5,150)
$btn_MB.Size = New-Object System.Drawing.Size(145,25)
$btn_MB.Font = $Font
$btn_MB.Text = "Motherboard"
$btn_MB.Add_Click($mb_info)
$MainForm.Controls.Add($btn_MB)
$btn_PhysicalDrives = New-Object System.Windows.Forms.Button
$btn_PhysicalDrives.Location = New-Object System.Drawing.Point(5,175)
$btn_PhysicalDrives.Size = New-Object System.Drawing.Size(145,25)
$btn_PhysicalDrives.Font = $Font
$btn_PhysicalDrives.Text = "Physical Drives"
$btn_PhysicalDrives.Add_Click($PhysicalDrives_info)
$MainForm.Controls.Add($btn_PhysicalDrives)
$btn_LogicalDrives = New-Object System.Windows.Forms.Button
$btn_LogicalDrives.Location = New-Object System.Drawing.Point(5,200)
$btn_LogicalDrives.Size = New-Object System.Drawing.Size(145,25)
$btn_LogicalDrives.Font = $Font
$btn_LogicalDrives.Text = "Logical Drives"
$btn_LogicalDrives.Add_Click($LogicalDrives_info)
$MainForm.Controls.Add($btn_LogicalDrives)
$btn_Graphics = New-Object System.Windows.Forms.Button
$btn_Graphics.Location = New-Object System.Drawing.Point(5,225)
$btn_Graphics.Size = New-Object System.Drawing.Size(145,25)
$btn_Graphics.Font = $Font
$btn_Graphics.Text = "Graphics"
$btn_Graphics.Add_Click($GPU_info)
$MainForm.Controls.Add($btn_Graphics)
$btn_Network = New-Object System.Windows.Forms.Button
$btn_Network.Location = New-Object System.Drawing.Point(5,250)
$btn_Network.Size = New-Object System.Drawing.Size(145,25)
$btn_Network.Font = $Font
$btn_Network.Text = "Network"
$btn_Network.Add_Click($Network_info)
$MainForm.Controls.Add($btn_Network)
$btn_NetSettings = New-Object System.Windows.Forms.Button
$btn_NetSettings.Location = New-Object System.Drawing.Point(5,275)
$btn_NetSettings.Size = New-Object System.Drawing.Size(145,25)
$btn_NetSettings.Font = $Font
$btn_NetSettings.Text = "Net Settings"
$btn_NetSettings.Add_Click($NetSettings_info)
$MainForm.Controls.Add($btn_NetSettings)
$btn_Monitors = New-Object System.Windows.Forms.Button
$btn_Monitors.Location = New-Object System.Drawing.Point(5,300)
$btn_Monitors.Size = New-Object System.Drawing.Size(145,25)
$btn_Monitors.Font = $Font
$btn_Monitors.Text = "Monitors"
$btn_Monitors.Add_Click($Monitor_info)
$MainForm.Controls.Add($btn_Monitors)
$btn_OS = New-Object System.Windows.Forms.Button
$btn_OS.Location = New-Object System.Drawing.Point(5,325)
$btn_OS.Size = New-Object System.Drawing.Size(145,25)
$btn_OS.Font = $Font
$btn_OS.Text = "OS"
$btn_OS.Add_Click($OS_info)
$MainForm.Controls.Add($btn_OS)
$btn_Keyboard = New-Object System.Windows.Forms.Button
$btn_Keyboard.Location = New-Object System.Drawing.Point(5,350)
$btn_Keyboard.Size = New-Object System.Drawing.Size(145,25)
$btn_Keyboard.Font = $Font
$btn_Keyboard.Text = "Keyboard"
$btn_Keyboard.Add_Click($Keyboard_info)
$MainForm.Controls.Add($btn_Keyboard)
$btn_Mouse = New-Object System.Windows.Forms.Button
$btn_Mouse.Location = New-Object System.Drawing.Point(5,375)
$btn_Mouse.Size = New-Object System.Drawing.Size(145,25)
$btn_Mouse.Font = $Font
$btn_Mouse.Text = "Mouse"
$btn_Mouse.Add_Click($Mouse_info)
$MainForm.Controls.Add($btn_Mouse)
$btn_CDROM = New-Object System.Windows.Forms.Button
$btn_CDROM.Location = New-Object System.Drawing.Point(5,400)
$btn_CDROM.Size = New-Object System.Drawing.Size(145,25)
$btn_CDROM.Font = $Font
$btn_CDROM.Text = "CDROM"
$btn_CDROM.Add_Click($CDROM_info)
$MainForm.Controls.Add($btn_CDROM)
$btn_Sound = New-Object System.Windows.Forms.Button
$btn_Sound.Location = New-Object System.Drawing.Point(5,425)
$btn_Sound.Size = New-Object System.Drawing.Size(145,25)
$btn_Sound.Font = $Font
$btn_Sound.Text = "Sound"
$btn_Sound.Add_Click($Sound_info)
$MainForm.Controls.Add($btn_Sound)
$btn_Printers = New-Object System.Windows.Forms.Button
$btn_Printers.Location = New-Object System.Drawing.Point(5,450)
$btn_Printers.Size = New-Object System.Drawing.Size(145,25)
$btn_Printers.Font = $Font
$btn_Printers.Text = "Printers"
$btn_Printers.Add_Click($Printers_info)
$MainForm.Controls.Add($btn_Printers)
$btn_Fan = New-Object System.Windows.Forms.Button
$btn_Fan.Location = New-Object System.Drawing.Point(5,475)
$btn_Fan.Size = New-Object System.Drawing.Size(145,25)
$btn_Fan.Font = $Font
$btn_Fan.Text = "Fan"
$btn_Fan.Add_Click($Fan_info)
$MainForm.Controls.Add($btn_Fan)
$btn_Battery = New-Object System.Windows.Forms.Button
$btn_Battery.Location = New-Object System.Drawing.Point(5,500)
$btn_Battery.Size = New-Object System.Drawing.Size(145,25)
$btn_Battery.Font = $Font
$btn_Battery.Text = "Battery"
$btn_Battery.Add_Click($Battery_info)
$MainForm.Controls.Add($btn_Battery)
$btn_PortBattery = New-Object System.Windows.Forms.Button
$btn_PortBattery.Location = New-Object System.Drawing.Point(5,525)
$btn_PortBattery.Size = New-Object System.Drawing.Size(145,25)
$btn_PortBattery.Font = $Font
$btn_PortBattery.Text = "Port Battery"
$btn_PortBattery.Add_Click($PortBattery_info)
$MainForm.Controls.Add($btn_PortBattery)
$btn_Software = New-Object System.Windows.Forms.Button
$btn_Software.Location = New-Object System.Drawing.Point(5,550)
$btn_Software.Size = New-Object System.Drawing.Size(145,25)
$btn_Software.Font = $Font
$btn_Software.Text = "Software"
$btn_Software.Add_Click($Software_info)
$MainForm.Controls.Add($btn_Software)
$btn_Process = New-Object System.Windows.Forms.Button
$btn_Process.Location = New-Object System.Drawing.Point(5,575)
$btn_Process.Size = New-Object System.Drawing.Size(145,25)
$btn_Process.Font = $Font
$btn_Process.Text = "Process"
$btn_Process.Add_Click($Process_info)
$MainForm.Controls.Add($btn_Process)
$btn_Services = New-Object System.Windows.Forms.Button
$btn_Services.Location = New-Object System.Drawing.Point(5,600)
$btn_Services.Size = New-Object System.Drawing.Size(145,25)
$btn_Services.Font = $Font
$btn_Services.Text = "Services"
$btn_Services.Add_Click($Services_info)
$MainForm.Controls.Add($btn_Services)
$btn_Ping = New-Object System.Windows.Forms.Button
$btn_Ping.Location = New-Object System.Drawing.Point(5,625)
$btn_Ping.Size = New-Object System.Drawing.Size(145,25)
$btn_Ping.Font = $Font
$btn_Ping.Text = "Ping Test"
$btn_Ping.Add_Click({Test-Ping})
$MainForm.Controls.Add($btn_Ping)
$btn_NetStat = New-Object System.Windows.Forms.Button
$btn_NetStat.Location = New-Object System.Drawing.Point(5,650)
$btn_NetStat.Size = New-Object System.Drawing.Size(145,25)
$btn_NetStat.Font = $Font
$btn_NetStat.Text = "NetStat"
$btn_NetStat.Add_Click({Get-NetStat})
$MainForm.Controls.Add($btn_NetStat)
$btn_RDP = New-Object System.Windows.Forms.Button
$btn_RDP.Location = New-Object System.Drawing.Point(5,675)
$btn_RDP.Size = New-Object System.Drawing.Size(145,25)
$btn_RDP.Font = $Font
$btn_RDP.Text = "RDP"
$btn_RDP.Add_Click($RDP_Connection)
$MainForm.Controls.Add($btn_RDP)
$btn_Export = New-Object System.Windows.Forms.Button
$btn_Export.Location = New-Object System.Drawing.Point(5,700)
$btn_Export.Size = New-Object System.Drawing.Size(145,25)
$btn_Export.Font = $Font
$btn_Export.Text = "Export"
$btn_Export.Add_Click($Export)
$MainForm.Controls.Add($btn_Export)
$MainForm.ShowDialog()