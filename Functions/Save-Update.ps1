function Save-Update {
    Param (
        [Parameter(Mandatory = $true)]
        [Array] $Update,

        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $false)]
        [switch] $UseProxy,

        [Parameter(Mandatory = $false)]
        [switch] $Force
    )

    Begin {
        $ScriptParentFolder = (Get-Item -Path $PSScriptRoot).Parent
        $ConfigFile = Join-Path -Path $ScriptParentFolder.FullName -ChildPath "Config.json"
        
        if (Test-Path -Path $ConfigFile -PathType Leaf -ErrorAction SilentlyContinue) {
            $Config = Get-Content -Path $ConfigFile | ConvertFrom-Json
        }

        $Overwrite = $false
        $SavePath = Join-Path -Path $Path -ChildPath $Update.Note
    
        $SavePathExists = Test-Path -Path $SavePath
        if ($SavePathExists) {
            $SavePathFiles = Get-ChildItem -Path $SavePath -File

            if ($SavePathFiles.Count -gt 0) {
                if ($SavePathExists -and (-not $Force.IsPresent)) {
                    $Skipped = $true
                    Write-Log "Update already seems to exist. Force param NOT defined. " -NoNewLine -NoTime
                    Write-Log "Skipped." -NoTime -ForegroundColor "Yellow"
                }
                if ($SavePathExists -and $Force.IsPresent) {
                    $Overwrite = $true
                    Write-Log "Update already seems to exist. Force param defined. " -NoNewLine -NoTime
                    Write-Log "Overwriting... " -NoNewLine -NoTime -ForegroundColor "Yellow"
                }
            }
            else {
                Write-Log "Destination folder already exists, but seems to be empty... Continuing with downloading..." -NoNewLine -NoTime
            }
        }
        else {
            $null = New-Item -Path $SavePath -ItemType Directory
        }

        $SaveParams = @{
            Updates = $Update
            Path    = $SavePath
            Force   = $Overwrite
            # Verbose = $true
        }

        if ($UseProxy.IsPresent) {
            $SaveParams.Proxy = "$($Config.ProxyUrl):$($Config.ProxyPort)"
        }
    }

    Process {
        if ($Skipped) {
            return
        }

        $SaveResult = Save-LatestUpdate @SaveParams
    }

    End {
        if ($Skipped) {
            return
        }

        if ($SaveResult) {
            Write-Log "OK!" -NoTime -ForegroundColor "Green"
            Write-Log "Update successfully downloaded to $($SaveResult.Target)"
        }
        else {
            Write-Log "Failed!" -NoTime -ForegroundColor "Red"
        }
    }
}