<#To list Everyone group permissions in the NTFS file system, run the following script in PowerShell, specifying the appropriate values for the "Network File Share Path" and ".csv File Name And Path" parameters.
Example:
.\List-EveryonePermissions.ps1 -NetworkFileSharePath "C:\Your\File\Path" -CsvFileNameAndPath "C:\Temp\Share.csv"

This script lists the permissions for the "Everyone" group in the specified NTFS file system path and exports the results to a CSV file. Make sure to replace "C:\Your\File\Path" and "C:\Temp\Share.csv" with the actual values you intend to use for the network file share path and CSV file name and path, respectively.#>

param (
    [string]$NetworkFileSharePath,
    [string]$CsvFileNameAndPath
)

# Check if the specified path exists
if (-not (Test-Path -Path $NetworkFileSharePath -PathType Container)) {
    Write-Error "The specified network file share path '$NetworkFileSharePath' does not exist."
    return
}

Get-ChildItem $NetworkFileSharePath -Recurse | Where-Object { $_.PsIsContainer } | ForEach-Object {
    $path1 = $_.FullName
    Get-Acl $_.FullName | ForEach-Object {
        $_.Access | Where-Object { $_.IdentityReference -like "everyone" } | Add-Member -MemberType NoteProperty -Name "ProjectCode" -Value $path1 -PassThru
    }
} | Export-Csv -Path $CsvFileNameAndPath -NoTypeInformation
