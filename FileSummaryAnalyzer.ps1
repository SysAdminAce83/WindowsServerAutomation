$Global:filesummary = $null
$global:rootpath = $null
$global:filesinRoot = $null
$global:lastfilename = $null

function Find-LastRecursionFile {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        $path
    )
    $s = Get-ChildItem -Path $path -Directory
    if ($null -ne $s) {
        Find-LastRecursionFile -path $s[-1].PSPath
    } else {
        $files = Get-ChildItem -Path $path -File
        if ($null -eq $files) {
            return $path
        } else {
            $lastfilename = $files[-1]
            return $lastfilename
        }
    }
}

function Summarize-Folder {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        $path,
        [Parameter(Mandatory = $true, Position = 1)]
        $sharename
    )

    $global:sharename = $sharename

    if ($null -eq $global:rootpath) {
        $global:rootpath = $path
    }

    if ($null -eq $global:filesinRoot) {
        if ($null -ne (Get-ChildItem -Path $global:rootpath -File)) {
            $global:filesinRoot = 1
        } else {
            $global:filesinRoot = 0
        }
    }

    if ($null -eq $global:filesummary) {
        $global:filesummary = 0
    }

    $s = Get-ChildItem -Path $path

    if ($null -eq $global:lastfilename -and $global:filesinRoot -eq 1) {
        $global:lastfilename = $s[-1]
    }

    if ($null -ne $s) {
        foreach ($ss in $s) {
            if ($ss.pstypenames[0] -eq "System.IO.DirectoryInfo") {
                Summarize-Folder -Path $ss.PSPath -sharename $sharename
            } else {
                $global:filesummary += $ss.length
                if ($global:filesinRoot -eq 1 -and $ss.Name -eq $global:lastfilename -and $ss.PSParentPath -eq "Microsoft.PowerShell.Core\FileSystem::$global:rootpath") {
                    $totalbyGB = $global:filesummary / 1GB
                    $summary = [PSCustomObject]@{
                        last_file            = $ss.name
                        total_capacity_in_GB = $totalbyGB
                        sharepath            = $global:sharename
                        LocalPath            = $global:rootpath
                    }
                    $summary
                } elseif ($global:filesinRoot -eq 0 -and $ss.Name -eq $global:lastfilenameForOnlyFolderinRootfloder.name -and $ss.PSParentPath -eq $global:lastfilenameForOnlyFolderinRootfloder.PSParentPath) {
                    $totalbyGB = $global:filesummary / 1GB
                    $summary = [PSCustomObject]@{
                        last_file            = $ss.name
                        total_capacity_in_GB = $totalbyGB
                        sharepath            = $global:sharename
                        LocalPath            = $global:rootpath
                    }
                    $summary
                } else {
                    # Unable to summarize $ss
                }
            }
        }
    } else {
        if ($path -eq $global:lastfilenameForOnlyFolderinRootfloder) {
            $totalbyGB = $global:filesummary / 1GB
            $summary = [PSCustomObject]@{
                last_file            = "no last file"
                total_capacity_in_GB = $totalbyGB
                sharepath            = $global:sharename
                LocalPath            = $global:rootpath
            }
            $summary
        } else {
            # Unable to summarize $ss
        }
    }
}

$global:lastfilenameForOnlyFolderinRootfloder = Find-LastRecursionFile -Path $args[0]
Summarize-Folder -Path $args[0] -ShareName $args[1] 2>$null
