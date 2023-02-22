#
# Common Functions
#
# Import this file using relative path in other script files
# i.e. 
# .\CommonFunctions.ps1
#
# then you can use the functions normally like:
# $doUninstall = ParseBool $uninstall
# or
# $answer = GetYN "Do you want to delete the temp directory? (Y/N)"

Function ParseBool {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [String]$inputVal
    )
    switch -regex ($inputVal.Trim()) {
        "^(1|true|yes|y|on|enabled)$" { $true }

        default { $false }
    }
}

Function GetYN {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [String]$msg,
        [string]$BackgroundColor = "Black",
        [string]$ForegroundColor = "DarkGreen"
    )

    Do {
        # Write-Host -BackgroundColor $BackgroundColor -ForegroundColor $ForegroundColor -NoNewline "${msg} "
        Write-Host -ForegroundColor $ForegroundColor -NoNewline "${msg} "
        $answer = Read-Host
    }
    Until(($answer -eq "Y") -or ($answer -eq "N"))

    return $answer
}

Function GetElevation {
    # see https://www.powershellgallery.com/packages/Sudo/2.1.0/Content/Private%5CGetElevation.ps1
    Write-Host "Checking admin rights on platform: $($PSVersionTable.platform.ToString())" -ForegroundColor Blue;

    # Windows check
    if ($PSVersionTable.PSEdition -eq "Desktop" -or $PSVersionTable.Platform -eq "Win32NT" -or $PSVersionTable.PSVersion.Major -le 5) {
        # get current user context
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
  
        # get administrator role
        $administratorsRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

        if ($currentPrincipal.IsInRole($administratorsRole)) {
            Write-Host "Success. Script is running with Administrator privileges!" -ForegroundColor Green
            return $true
        }
        else {
            return $false
        }
    }
    
    # Unix, Linux and Mac OSX Check
    if ($PSVersionTable.Platform -eq "Unix") {
        if ($(whoami) -eq "root") {
            Write-Host "Success. Script is running with Administrator privileges!" -ForegroundColor Green
            return $true            
        }
        else {
            Write-Warning "$(whoami) is not an Administrator!"
            return $false
        }
    }
}

Function ExecuteElevation {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string[]]$argumentsList
    )

    Write-Host "Relaunching using arguments:" $argumentsList -ForegroundColor Blue

    # Windows check
    if ($PSVersionTable.PSEdition -eq "Desktop" -or $PSVersionTable.Platform -eq "Win32NT") {
        # Relaunch as an elevated process
        Start-Process powershell -Verb runAs -ArgumentList $argumentsList
    }

    # Unix, Linux and Mac OSX Check
    if ($PSVersionTable.Platform -eq "Unix") {
        # Relaunch as an elevated process
        sudo pwsh $argumentsList
    }

    exit
}