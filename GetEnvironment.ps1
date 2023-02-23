Function GetEnvironmentVariables {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True)]
        [String] $cloudHomeEnvVar
    )

    # Include the GetEnvironment.ps1 file
    # . (Join-Path $PSScriptRoot GetEnvironment.ps1)
    # $environment = GetEnvironmentVariables "OneDrive"
    # Write-Host $environment.userName

    # https://adamtheautomator.com/powershell-environment-variables/
    # List PowerShell's Environmental Variables
    # Get-Childitem -Path Env:* | Sort-Object Name

    $cloudHomeDir = [Environment]::GetEnvironmentVariable($cloudHomeEnvVar)
    $userName = [Environment]::GetEnvironmentVariable("UserName") # $env:USERNAME
    $userDocuments = [Environment]::GetFolderPath("MyDocuments") # Join-Path $env:USERPROFILE "Documents"
    $appData = [Environment]::GetFolderPath('ApplicationData') # $env:APPDATA
    $programData = [Environment]::GetFolderPath("CommonApplicationData") # $env:ProgramData
    $programFiles = [Environment]::GetFolderPath("ProgramFiles") # $env:ProgramFiles
    $programFilesx86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)") # ${Env:ProgramFiles(x86)}
    $commonProgramFilesx86 = [Environment]::GetEnvironmentVariable("CommonProgramFiles(x86)") # ${Env:CommonProgramFiles(x86)}
 
    Write-Host ""
    Write-Host "Environment Variables:" -ForegroundColor Magenta
    Write-Host "${cloudHomeEnvVar}: $cloudHomeDir" -ForegroundColor Magenta
    Write-Host "UserName: $userName" -ForegroundColor Magenta
    Write-Host "userDocuments: $userDocuments" -ForegroundColor Magenta
    Write-Host "AppData: $appData" -ForegroundColor Magenta
    Write-Host "ProgramData: $programData" -ForegroundColor Magenta
    Write-Host "ProgramFiles: $programFiles" -ForegroundColor Magenta
    Write-Host "ProgramFilesx86: $programFilesx86" -ForegroundColor Magenta
    Write-Host "CommonProgramFilesx86: $commonProgramFilesx86" -ForegroundColor Magenta
    Write-Host ""

    #############################
    # DEBUG WITH DUMMY VARIABLES
    if ($Debug) {
        Write-Host "!!!!!! DEBUGGING WITH DUMMY VARIABLES !!!!!!!"  -ForegroundColor Red
    
        $cloudHomeDir = "/Users/perivar/OneDrive/"
        $userName = $(whoami)
        $userDocuments = "/Users/perivar/Temp"
        $appData = "/Users/perivar/Temp/appdata"
        $programData = "/Users/perivar/Temp/programdata"
        $programFiles = "/Users/perivar/Temp/programfiles"
        $programFilesx86 = "/Users/perivar/Temp/programFilesx86"
        $commonProgramFilesx86 = "/Users/perivar/Temp/commonProgramFilesx86"
    }
    #############################

    # Make sure the cloudHomeDir parameter exists
    if ($cloudHomeDir -ne $null) {
        Write-Host "The $cloudHomeEnvVar environment variable was found: $cloudHomeDir" -ForegroundColor Green
    }
    else {
        Write-Error "The $cloudHomeEnvVar environment variable cannot be found!"
        exit    
    }

    $environment = [PSCustomObject]@{
        cloudHomeDir          = $cloudHomeDir 
        userName              = $userName 
        userDocuments         = $userDocuments 
        appData               = $appData 
        programData           = $programData 
        programFiles          = $programFiles 
        programFilesx86       = $programFilesx86 
        commonProgramFilesx86 = $commonProgramFilesx86 
    }

    return $environment
}