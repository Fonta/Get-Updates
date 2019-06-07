Param(
    [Parameter(Mandatory = $False)]
    [switch] $UseProxy,

    [switch] $Force
)

$null = Set-PSBreakpoint -Variable now -Action {$global:now = Get-Date} -Mode Read
$null = Set-PSBreakpoint -Variable timeNow -Action {$global:timeNow = (Get-Date -f 'HH:mm:ss')} -Mode Read

# Import modules and functions folder
Get-ChildItem -Path "$PSScriptRoot\Modules" -Directory | ForEach-Object { Import-Module $_.FullName -Force }
Get-ChildItem -Path "$PSScriptRoot\Functions" | ForEach-Object { . $_.FullName }

# Making sure the LatestUpdate module is loaded
if (-not (Get-Module -Name "LatestUpdate")) {
    if (-not (Get-Module -Name "LatestUpdate" -ListAvailable)) {
        throw '"LatestUpdate" module is unavailable. Please make sure the module is available on the machine or placed in the Modules folder. The module can be downloaded from https://github.com/aaronparker/LatestUpdate/.'
    }
    else {
        try {
            Import-Module -Name "LatestUpdate" -ErrorAction Stop
        }
        catch {
            throw 'Failed to import the "LatestUpdate" module!'
        }
    }
} 

# Set TLS to 1.2 or we won't be able to connect to the internet
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Get the config files for the OSs to patch. It will only include .json files.
$OSConfigFiles = Get-ChildItem -Path "$PSScriptRoot\OSConfigs" | Where-Object { $_.Name -like "*.json" } 

foreach ($OSConfigFile in $OSConfigFiles) {
    $OSInfo = (Get-Content $OSConfigFile.FullName) -Join "`n" | ConvertFrom-Json
    $downloadLocations = @()
    $updates2Keep = @()

    Write-Output ""
    Write-Log "############### $($OSInfo.Name) #############################################################################################" -NoTime
    Write-Log "*** Gathering information about the latest updates ***" -NoTime

    if ($OSInfo.StackUpdatePath) {
        Write-Log "Getting latest Stack update... " -NoNewLine
        $LatestStack = Get-LatestServicingStackUpdate -Version $OSInfo.Version | Where-Object {$_.Note -match $OSInfo.Name}

        if ($LatestStack) {
            Write-Log "OK!" -NoTime -ForegroundColor "Green"
            Write-Log "Latest stack update is: $($LatestStack.Note)"

            $downloadLocations += $OSInfo.StackUpdatePath
            $updates2Keep += $LatestStack.Note
        }
        else {
            Write-Log "Failed!" -NoTime -ForegroundColor "Red"
        }
    }

    if ($OSInfo.CumulativeUpdatePath) {
        Write-Log "Getting latest Cumulative update... " -NoNewLine
        $LatestCumulativeUpdate = Get-LatestCumulativeUpdate -Version $OSInfo.Version | Where-Object {$_.Note -match $OSInfo.Name -and $_.Note -like "*Cumulative*"}

        if ($LatestCumulativeUpdate) {
            Write-Log "OK!" -NoTime -ForegroundColor "Green"
            Write-Log "Latest Cumulative update is: $($LatestCumulativeUpdate.Note)"

            $downloadLocations += $OSInfo.CumulativeUpdatePath
            $updates2Keep += $LatestCumulativeUpdate.Note
        }
        else {
            Write-Log "Failed!" -NoTime -ForegroundColor "Red"
        }
    }

    if ($OSInfo.AdditionalUpdatesPath) {
        $downloadLocations += $OSInfo.AdditionalUpdatesPath

        foreach ($AddUpdate in $OSInfo.AdditionalUpdates) {
            if ($AddUpdate -match ".net") {
                Write-Log "Getting latest .NET Framework update... " -NoNewLine
                $LastNETFW = Get-LatestNetFrameworkUpdate | Where-Object {$_.Note -match $OSInfo.Name -and $_.Note -match $AddUpdate}

                if ($LastNETFW) {
                    Write-Log "OK!" -NoTime -ForegroundColor "Green"
                    Write-Log "Latest .NET update is: $($LastNETFW.Note)"

                    $updates2Keep += $LastNETFW.Note
                }
                else {
                    Write-Log "Failed!" -NoTime -ForegroundColor "Red"
                }
            }

            if ($AddUpdate -match "Flash") {
                Write-Log "Getting latest Flash update... " -NoNewLine
                $LatestFlash = Get-LatestAdobeFlashUpdate | Where-Object {$_.Note -match $OSInfo.Name}

                if ($LatestFlash) {
                    Write-Log "OK!" -NoTime -ForegroundColor "Green"
                    Write-Log "Latest Flash is: $($LatestFlash.Note)"

                    $updates2Keep += $LatestFlash.Note
                }
                else {
                    Write-Log "Failed!" -NoTime -ForegroundColor "Red"
                }
            }
        }
    }

    Write-Output ""
    Write-Log "*** Information gathered, download the updates ***" -NoTime
    Write-Log "Cleaning up any old updates from the download destinations... " -NoNewLine
    $clearResult = Clear-DownloadLocations -Locations $downloadLocations -Keep $updates2Keep
    if ($clearResult) {
        Write-Log "OK!" -NoTime -ForegroundColor "Green"
    }
    else {
        Write-Log "Failed!" -NoTime -ForegroundColor "Red"
    }

    if ($LatestStack) {
        Write-Log "Downloading Stack update... " -NoNewLine
        $downloadDuration = Measure-Command -Expression { Save-Update -Update $LatestStack -Path $OSInfo.StackUpdatePath -Force:$($Force.IsPresent) -UseProxy:$($UseProxy.IsPresent) }
        Write-Log "Duration of download was: $($downloadDuration.TotalSeconds) seconds."
    }

    if ($LatestCumulativeUpdate) {
        Write-Log "Downloading Cumulative update... " -NoNewLine
        $downloadDuration = Measure-Command -Expression { Save-Update -Update $LatestCumulativeUpdate -Path $OSInfo.CumulativeUpdatePath -Force:$($Force.IsPresent) -UseProxy:$($UseProxy.IsPresent) }
        Write-Log "Duration of download was: $($downloadDuration.TotalSeconds) seconds."
    }

    if ($LastNETFW) {
        Write-Log "Downloading .NET Framework update... " -NoNewLine
        $downloadDuration = Measure-Command -Expression { Save-Update -Update $LastNETFW -Path $OSInfo.AdditionalUpdatesPath -Force:$($Force.IsPresent) -UseProxy:$($UseProxy.IsPresent) }
        Write-Log "Duration of download was: $($downloadDuration.TotalSeconds) seconds."
    }

    if ($LatestFlash) {
        Write-Log "Downloading Adobe Flash update... " -NoNewLine
        $downloadDuration = Measure-Command -Expression { Save-Update -Update $LatestFlash -Path $OSInfo.AdditionalUpdatesPath -Force:$($Force.IsPresent) -UseProxy:$($UseProxy.IsPresent) }
        Write-Log "Duration of download was: $($downloadDuration.TotalSeconds) seconds."
    }

    Write-Log "#################################################################################################################################" -NoTime
}