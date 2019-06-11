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
        $ConfigFile = Join-Path -Path $ScriptParentFolder -ChildPath "Config.json"
        
        if (Test-Path -Path $ConfigFile -PathType Leaf -ErrorAction SilentlyContinue) {
            $Config = (Get-Content -Path $ConfigFile) -join "`n" | ConvertFrom-Json
        }        

        $Download = $true
        $Overwrite = $false
        $SavePath = Join-Path -Path $Path -ChildPath $Update.Note
    
        $SavePathExists = Test-Path -Path $SavePath
        if ($SavePathExists -and (-not $Force.IsPresent)) {
            Write-Log "Update already seems to exist. Force param NOT defined. " -NoNewLine -NoTime
            Write-Log "Skipping." -NoTime -ForegroundColor "Yellow"
            $Download = $false
        }
        if ($SavePathExists -and $Force.IsPresent) {
            Write-Log "Update already seems to exist. Force param defined. " -NoNewLine -NoTime
            Write-Log "Overwriting... " -NoNewLine -NoTime -ForegroundColor "Yellow"
            $Overwrite = $true
        }
        if (-not $SavePathExists) {
            $null = New-Item -Path $SavePath -ItemType Directory
        }
    }

    Process {
        if ($Download) {
            $SaveParams = @{
                Path  = $SavePath
                Force = $Overwrite
                # Verbose = $true
            }
    
            if ($UseProxy.IsPresent) {
                $SaveParams.Proxy = "$($Config.ProxyUrl):$($Config.ProxyPort)"
            }

            $SaveResult = $Update | Save-LatestUpdate @SaveParams
        }
    }

    End {
        if ($SaveResult) {
            Write-Log "OK!" -NoTime -ForegroundColor "Green"
            Write-Log "Update successfully downloaded to $($SaveResult.Target)"
        }
        else {
            Write-Log "Failed!" -NoTime -ForegroundColor "Red"
        }
    }
}