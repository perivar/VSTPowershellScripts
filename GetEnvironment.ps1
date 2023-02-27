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
    $userProfile = [Environment]::GetEnvironmentVariable("UserProfile")

    # set user document folder based on the userProfile
    if ($null -ne $userProfile) {
        # user document path that ignores if the user has made changes.
        $userDocuments = Join-Path $userProfile "Documents" # e.g. C:\Users\<user>\Documents
    }
    else {
        # user document path that takes into account if the user has moved it, e.g. to OneDrive
        $userDocuments = [Environment]::GetFolderPath("MyDocuments") # e.g. C:\Users\<user>\OneDrive\Documents
    }
    
    $appData = [Environment]::GetFolderPath('ApplicationData') # $env:APPDATA (i.e. C:\Users\<user>\AppData\Roaming)
    $localAppData = [Environment]::GetFolderPath('LocalApplicationData') # $env:LOCALAPPDATA (i.e. C:\Users\<user>\AppData\Local)
    $programData = [Environment]::GetFolderPath("CommonApplicationData") # $env:ProgramData
    $programFiles = [Environment]::GetFolderPath("ProgramFiles") #${Env:ProgramFiles}
    $programFilesx86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)") # ${Env:ProgramFiles(x86)}
    $commonProgramFiles = [Environment]::GetEnvironmentVariable("CommonProgramFiles") # ${Env:CommonProgramFiles}
    $commonProgramFilesx86 = [Environment]::GetEnvironmentVariable("CommonProgramFiles(x86)") # ${Env:CommonProgramFiles(x86)}

    $tempDir = [IO.Path]::GetTempPath()
 
    Write-Host ""
    Write-Host "Environment Variables:" -ForegroundColor Magenta
    Write-Host "${cloudHomeEnvVar}: $cloudHomeDir" -ForegroundColor Magenta
    Write-Host "UserName: $userName" -ForegroundColor Magenta
    Write-Host "UserProfile: $userProfile" -ForegroundColor Magenta
    Write-Host "UserDocuments: $userDocuments" -ForegroundColor Magenta
    Write-Host "AppData: $appData" -ForegroundColor Magenta
    Write-Host "LocalAppData: $localAppData" -ForegroundColor Magenta
    Write-Host "ProgramData: $programData" -ForegroundColor Magenta
    Write-Host "ProgramFiles: $programFiles" -ForegroundColor Magenta
    Write-Host "ProgramFilesx86: $programFilesx86" -ForegroundColor Magenta
    Write-Host "CommonProgramFiles: $commonProgramFiles" -ForegroundColor Magenta
    Write-Host "CommonProgramFilesx86: $commonProgramFilesx86" -ForegroundColor Magenta
    Write-Host "tempDir: $tempDir" -ForegroundColor Magenta
    Write-Host ""

    #############################
    # DEBUG WITH DUMMY VARIABLES
    if ($Debug) {    
        $cloudHomeDir = "/Users/perivar/OneDrive/"
        $userName = $(whoami)
        $userProfile = "/Users/perivar/Temp/"
        $userDocuments = "/Users/perivar/Temp/userDocuments"
        $appData = "/Users/perivar/Temp/appdata"
        $localAppData = "/Users/perivar/Temp/localAppData"
        $programData = "/Users/perivar/Temp/programdata"
        $programFiles = "/Users/perivar/Temp/programfiles"
        $programFilesx86 = "/Users/perivar/Temp/programFilesx86"
        $commonProgramFiles = "/Users/perivar/Temp/commonProgramFiles"
        $commonProgramFilesx86 = "/Users/perivar/Temp/commonProgramFilesx86"

        Write-Host ""
        Write-Host "!! Setting Dummy Environment Variables: !!" -ForegroundColor Red
        Write-Host "${cloudHomeEnvVar}: $cloudHomeDir" -ForegroundColor Red
        Write-Host "UserName: $userName" -ForegroundColor Red
        Write-Host "UserProfile: $userProfile" -ForegroundColor Red
        Write-Host "UserDocuments: $userDocuments" -ForegroundColor Red
        Write-Host "AppData: $appData" -ForegroundColor Red
        Write-Host "LocalAppData: $localAppData" -ForegroundColor Red
        Write-Host "ProgramData: $programData" -ForegroundColor Red
        Write-Host "ProgramFiles: $programFiles" -ForegroundColor Red
        Write-Host "ProgramFilesx86: $programFilesx86" -ForegroundColor Red
        Write-Host "CommonProgramFiles: $commonProgramFiles" -ForegroundColor Red
        Write-Host "CommonProgramFilesx86: $commonProgramFilesx86" -ForegroundColor Red
        Write-Host "tempDir: $tempDir" -ForegroundColor Red
        Write-Host ""    
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