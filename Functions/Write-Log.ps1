Function Write-Log {
    param (
        [Parameter(Mandatory = $false)]
        [string] $Message,

        [Parameter(Mandatory = $false)]
        [string] $ForegroundColor,

        [Parameter(Mandatory = $false)]
        [switch] $NoNewLine,

        [Parameter(Mandatory = $false)]
        [switch] $FullDate,

        [Parameter(Mandatory = $false)]
        [switch] $NoTime
    )

    Begin {
        $date = Get-Date
        $langEn = New-Object System.Globalization.CultureInfo('en-US')
        $month = $langEn.DateTimeFormat.GetMonthName($date.Month)
        $year = $date.Year

        $scriptParentFolder = (Get-Item -Path $PSScriptRoot).Parent
        $logFolder = Join-Path -Path $scriptParentFolder.FullName -ChildPath "Logs"
        $logFile = Join-Path -Path $logFolder -ChildPath "$month-$year.log"

        if (-not (Test-Path -Path $logFolder -ErrorAction SilentlyContinue)) {
            $null = New-Item -Path $logFolder -ItemType Directory -ErrorAction SilentlyContinue
        }

        $WriteHostParams = @{}

        if ($ForegroundColor) {
            $WriteHostParams.Add("ForegroundColor", $ForegroundColor)
        }

        if ($NoNewLine.IsPresent) {
            $WriteHostParams.Add("NoNewLine", $true)
        }
    }

    Process {
        Add-Content -Value "$now $Message" -Path $logFile

        if ($FullDate.IsPresent) {
            Write-Host "$now $Message" @WriteHostParams
        }
        if ($NoTime.IsPresent) {
            Write-Host $Message @WriteHostParams
        }
        else {
            Write-Host "$timeNow $Message" @WriteHostParams
        }
        
    }

}