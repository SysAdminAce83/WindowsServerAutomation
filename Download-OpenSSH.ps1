# Set network connection protocol to TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Define the OpenSSH latest release URL
$releaseUrl = 'https://github.com/PowerShell/Win32-OpenSSH/releases/latest/'

# Create a web request to retrieve the latest release download link
$request = [System.Net.WebRequest]::Create($releaseUrl)
$request.AllowAutoRedirect = $false
$response = $request.GetResponse()
$downloadLink = ($response.GetResponseHeader("Location") -replace '/tag/', '/download/') + '/OpenSSH-Win64.zip'

# Download the latest OpenSSH for Windows package to the current working directory
$downloadPath = Join-Path (Get-Location).Path 'OpenSSH-Win64.zip'
$webClient = [System.Net.WebClient]::new()
$webClient.DownloadFile($downloadLink, $downloadPath)

# Extract the ZIP to a temporary location
$extractedPath = Join-Path $env:temp 'OpenSSH-Win64'
Expand-Archive -Path $downloadPath -DestinationPath $extractedPath -Force

# Move the extracted ZIP contents from the temporary location to C:\Program Files\OpenSSH\
$installPath = 'C:\Program Files\OpenSSH'
Move-Item $extractedPath -Destination $installPath -Force

# Unblock the files in C:\Program Files\OpenSSH\
Get-ChildItem -Path $installPath | Unblock-File

# Run the installation script for SSH server
& "$installPath\install-sshd.ps1"

# Set the SSH server service's startup type to automatic
Set-Service sshd -StartupType Automatic

# Start the SSH server service
Start-Service sshd

# Create a firewall rule to allow SSH traffic
New-NetFirewallRule -Name sshd -DisplayName 'Allow SSH' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

# Clean up: Remove the downloaded ZIP file
Remove-Item $downloadPath -Force