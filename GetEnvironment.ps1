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
    #$userDocuments = [Environment]::GetFolderPath("MyDocuments") # e.g. C:\Users\<user>\OneDrive\Documents
    $userDocuments = Join-Path $env:USERPROFILE "Documents" # e.g. C:\Users\<user>\Documents
    $appData = [Environment]::GetFolderPath('ApplicationData') # $env:APPDATA (i.e. C:\Users\<user>\AppData\Roaming)
    $localAppData = [Environment]::GetFolderPath('LocalApplicationData') # $env:LOCALAPPDATA (i.e. C:\Users\<user>\AppData\Local)
    $programData = [Environment]::GetFolderPath("CommonApplicationData") # $env:ProgramData
    $programFiles = [Environment]::GetFolderPath("ProgramFiles") #${Env:ProgramFiles}
    $programFilesx86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)") # ${Env:ProgramFiles(x86)}
    $commonProgramFiles = [Environment]::GetEnvironmentVariable("CommonProgramFiles") # ${Env:CommonProgramFiles}
    $commonProgramFilesx86 = [Environment]::GetEnvironmentVariable("CommonProgramFiles(x86)") # ${Env:CommonProgramFiles(x86)}
 
    Write-Host ""
    Write-Host "Environment Variables:" -ForegroundColor Magenta
    Write-Host "${cloudHomeEnvVar}: $cloudHomeDir" -ForegroundColor Magenta
    Write-Host "UserName: $userName" -ForegroundColor Magenta
    Write-Host "UserDocuments: $userDocuments" -ForegroundColor Magenta
    Write-Host "AppData: $appData" -ForegroundColor Magenta
    Write-Host "LocalAppData: $localAppData" -ForegroundColor Magenta
    Write-Host "ProgramData: $programData" -ForegroundColor Magenta
    Write-Host "ProgramFiles: $programFiles" -ForegroundColor Magenta
    Write-Host "ProgramFilesx86: $programFilesx86" -ForegroundColor Magenta
    Write-Host "CommonProgramFiles: $commonProgramFiles" -ForegroundColor Magenta
    Write-Host "CommonProgramFilesx86: $commonProgramFilesx86" -ForegroundColor Magenta
    Write-Host ""

    #############################
    # DEBUG WITH DUMMY VARIABLES
    if ($Debug) {
        Write-Host "!!!!!! DEBUGGING WITH DUMMY VARIABLES !!!!!!!"  -ForegroundColor Red
    
        $cloudHomeDir = "/Users/perivar/OneDrive/"
        $userName = $(whoami)
        $userDocuments = "/Users/perivar/Temp/userDocuments"
        $appData = "/Users/perivar/Temp/appdata"
        $localAppData = "/Users/perivar/Temp/localAppData"
        $programData = "/Users/perivar/Temp/programdata"
        $programFiles = "/Users/perivar/Temp/programfiles"
        $programFilesx86 = "/Users/perivar/Temp/programFilesx86"
        $commonProgramFiles = "/Users/perivar/Temp/commonProgramFiles"
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
        localAppData          = $localAppData 
        programData           = $programData 
        programFiles          = $programFiles 
        programFilesx86       = $programFilesx86 
        commonProgramFiles    = $commonProgramFiles
        commonProgramFilesx86 = $commonProgramFilesx86 
    }

    return $environment
}