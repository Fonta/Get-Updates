Function Clear-DownloadLocations {
    param (
        [Parameter(Mandatory = $true)]
        [array] $Locations,

        [Parameter(Mandatory = $false)]
        [array] $Keep
    )

    try {
        foreach ($path in $Locations) {
            if (Test-Path -Path $path -ErrorAction SilentlyContinue) {
                $itemsToRemove = Get-ChildItem -Path $path | Where-Object {$_.PSIsContainer -and ($Keep -notcontains $_.Name)}
                $itemsToRemove | Remove-Item -Force -Recurse
            }
        }
    }
    catch {
        return $false
    }
    
    return $true
}