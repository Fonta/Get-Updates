Param(
    [Parameter(Mandatory = $False)]
    [switch] $UseProxy,

    [switch] $Force
)

# Import modules and functions folder
Get-ChildItem -Path "$PSScriptRoot\Modules" -Directory | ForEach-Object { Import-Module $_.FullName -Force }

# Set TLS to 1.2 or we won't be able to connect
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Get the config files for the OSs to patch. It will only include .json files.
$OSConfigFiles = Get-ChildItem -Path "$PSScriptRoot\OSConfigs" | Where-Object { $_.Name -like "*.json" } 
function Save-Update {
    param (
        [Array] $Update,
        
        [string] $Path,

        [Parameter(Mandatory = $False)]
        [switch] $UseProxy,

        [switch] $Force
    )

    $Download = $true
    $Overwrite = $false
    $SavePath = Join-Path -Path $Path -ChildPath $Update.Note

    $SavePathExists = Test-Path -Path $SavePath
    if ($SavePathExists -and (-not $Force.IsPresent)) {
        Write-Output "Update already seems to exist. Force param NOT defined. Skipping."
        $Download = $false
    }
    if ($SavePathExists -and $Force.IsPresent) {
        Write-Output "Update already seems to exist. Force param defined. Overwriting."
        $Overwrite = $true
    }
    if (-not $SavePathExists) {
        $null = New-Item -Path $SavePath -ItemType Directory
    }

    if ($Download) {
        $SaveParams = @{
            Path = $SavePath
            Force = $Overwrite
            # Verbose = $true
        }

        if ($UseProxy.IsPresent) {
            $SaveParams.ProxyURL = "url.toproxy.com:8080"
        }

        $SaveResult = $Update | Save-LatestUpdate  @SaveParams

        if ($SaveResult) {
            Write-Output "Successfully downloaded the update to $SaveResult"
        }
        else {
            Write-Output "Failed to download the update!"
        }

    }
}

foreach ($OSConfigFile in $OSConfigFiles) {
    $OSInfo = (Get-Content $OSConfigFile.FullName) -Join "`n" | ConvertFrom-Json

    Write-Output "################## $($OSInfo.Name) ##################"
    Write-Output ""

    if ($OSInfo.StackUpdatesPath) {
        Write-Output "Getting latest Stack update"
        $LatestStack = Get-LatestServicingStack -Version $OSInfo.Version | Where-Object {$_.Note -match $OSInfo.Name}
        $LatestStack
        Write-Output "Latest stack is: $($LatestStack.Note)" 
        Save-Update -Update $LatestStack -Path $OSInfo.StackUpdatesPath -Force:$($Force.IsPresent) -UseProxy:$($UseProxy.IsPresent)
        Write-Output ""
    }

    if ($OSInfo.CumulativeUpdatesPath) {
        Write-Output "Getting latest Cumulative update"
        $LatestUpdate = Get-LatestUpdate -WindowsVersion $OSInfo.WindowsVersion -Build $OSInfo.Build | Where-Object {$_.Note -match $OSInfo.Name -and $_.Note -like "*Cumulative*"}
        Write-Output "Latest Cumulative is: $($LatestUpdate.Note)"
        Save-Update -Update $LatestUpdate -Path $OSInfo.CumulativeUpdatesPath -Force:$($Force.IsPresent) -UseProxy:$($UseProxy.IsPresent)
        Write-Output ""
    }

    if ($OSInfo.AdditionalUpdatesPath) {
        foreach ($AddUpdate in $OSInfo.AdditionalUpdates) {
            if ($AddUpdate -match ".net") {
                Write-Output "Getting latest .NET Framework update..."
                $LastNETFW = Get-LatestNETFramework -OS $OSInfo.Name
                Write-Output "Latest .NET is: $($LastNETFW.Note)"
                Save-Update -Update $LastNETFW -Path $OSInfo.AdditionalUpdatesPath -Force:$($Force.IsPresent) -UseProxy:$($UseProxy.IsPresent)
                Write-Output ""
            }

            if ($AddUpdate -match "Flash") {
                Write-Output "Getting latest Flash update..."
                $LatestFlash = Get-LatestFlash -OS $OSInfo.Name | Where-Object {$_.Note -match $OSInfo.Name}
                Write-Output "Latest Flash is: $($LatestFlash.Note)"
                Save-Update -Update $LatestFlash -Path $OSInfo.AdditionalUpdatesPath -Force:$($Force.IsPresent) -UseProxy:$($UseProxy.IsPresent)
                Write-Output ""
            }
        }
    }

    Write-Output "######################################################"
    Write-Output ""
}
