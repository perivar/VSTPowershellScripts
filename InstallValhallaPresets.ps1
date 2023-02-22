# set script parameters here
param (
    [Parameter(Mandatory = $false, Position = 0, Helpmessage = "Do you want to uninstall? [Y/N]")]
    [ValidateSet(0, 1, 'true', 'false', 'yes', 'no', 'y', 'n', 'on', 'off', 'enabled', 'disabled')]
    [String]$uninstall = 'false',

    # make sure to add the scriptStatus parameter to ensure we do not elevate in never-ending loop
    [Parameter(Mandatory = $false, Position = 1)]
    [String]$scriptStatus 
)

# output if using -Verbose
$Verbose = [bool]$PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Verbose")
if ($Verbose) {
    Write-Verbose "-Verbose flag found on $($PSVersionTable.Platform)"
}

# output if using -Debug
$Debug = [bool]$PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Debug")
if ($Debug) {
    Write-Debug "-Debug flag found on $($PSVersionTable.Platform)"
}

# ############### #
#                 #
# START OF SCRIPT #
#                 #
# ############### #

# Include the CommonFunctions.ps1 file
. (Join-Path $PSScriptRoot CommonFunctions.ps1)

if (!$(GetElevation)) {

    # check status of relaunch so that we do not run in a never-ending loop
    # if scriptStatus is RELAUNCHING, this means we were not able to elevate to Admin
    # Write-Host "Script status: ${scriptStatus}" -ForegroundColor Yellow
    if (($scriptStatus -eq "RELAUNCHING")) {
        Write-Error "$($MyInvocation.MyCommand.Name) failed relaunching with admin rights, exiting ..."
        exit
    }
    
    Write-Error "$($MyInvocation.MyCommand.Name) is not running as Administrator, attempting to elevate..."
    
    $argumentsList = @(
        '-File',
        $MyInvocation.MyCommand.Definition,
        $uninstall
        "RELAUNCHING"
        $Debug ? "-Debug" : $null
        $Verbose ? "-Verbose" : $null
    )

    ExecuteElevation $argumentsList
}

# ###################################################################
#
# The following runs only after the script is re-launched as elevated.
#                
# ###################################################################

# Convert script parameter to boolean
$doUninstall = ParseBool $uninstall
Write-Host "Parameter found: uninstall: $doUninstall" -ForegroundColor Green

# https://adamtheautomator.com/powershell-environment-variables/
# List PowerShell's Environmental Variables
# Get-Childitem -Path Env:* | Sort-Object Name

$cloudHomeEnvVar = "OneDrive" 
$cloudHomeDir = [Environment]::GetEnvironmentVariable($cloudHomeEnvVar)
$userName = [Environment]::GetEnvironmentVariable("UserName") # $env:USERNAME
$programData = [Environment]::GetFolderPath("CommonApplicationData") # $env:ProgramData
$appData = [Environment]::GetFolderPath('ApplicationData') # $env:APPDATA
$programFiles = [Environment]::GetFolderPath("ProgramFiles") # $env:ProgramFiles

Write-Host ""
Write-Host "Environment Variables:" -ForegroundColor Magenta
Write-Host "${cloudHomeEnvVar}: $cloudHomeDir" -ForegroundColor Magenta
Write-Host "userName: $userName" -ForegroundColor Magenta
Write-Host "appData: $appData" -ForegroundColor Magenta
Write-Host "programData: $programData" -ForegroundColor Magenta
Write-Host "programFiles: $programFiles" -ForegroundColor Magenta
Write-Host ""

#############################
# DEBUG WITH DUMMY VARIABLES
if ($Debug) {
    Write-Host "!!!!!! DEBUGGING WITH DUMMY VARIABLES !!!!!!!"  -ForegroundColor Red
    $userName = $(whoami)
    $cloudHomeDir = "/Users/perivar/OneDrive/"
    $programData = "/Users/perivar/Temp/programdata"
    $appData = "/Users/perivar/Temp/appdata"
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

# define paths
$sourceProgramData = Join-Path "${programData}" "Valhalla DSP, LLC"
$targetProgramData = Join-Path "${cloudHomeDir}" "Audio" "Audio Software" "Valhalla DSP, LLC"
$sourceRoaming = Join-Path "${appData}" "Valhalla DSP, LLC"
$targetRoaming = Join-Path "${cloudHomeDir}" "Audio" "Audio Software" "Valhalla DSP, LLC"

Write-Host ""
Write-Host "Directory Paths:" -ForegroundColor Magenta
Write-Host "sourceProgramData: $sourceProgramData" -ForegroundColor Magenta
Write-Host "targetProgramData: $targetProgramData" -ForegroundColor Magenta
Write-Host "sourceRoaming: $sourceRoaming" -ForegroundColor Magenta
Write-Host "targetRoaming: $targetRoaming" -ForegroundColor Magenta
Write-Host ""

# +-----------------------+-----------------------------------------------------------+
# | mklink syntax         | PowerShell equivalent                                     |
# +-----------------------+-----------------------------------------------------------+
# | mklink Link Target    | New-Item -ItemType SymbolicLink -Name Link -Target Target |
# | mklink /D Link Target | New-Item -ItemType SymbolicLink -Name Link -Target Target |
# | mklink /H Link Target | New-Item -ItemType HardLink -Name Link -Target Target     |
# | mklink /J Link Target | New-Item -ItemType Junction -Name Link -Target Target     |
# +-----------------------+-----------------------------------------------------------+
#
# https://www.delftstack.com/howto/powershell/create-symbolic-links-in-powershell/
#
# Examples:
# DELETE:   (Get-Item C:\SPI).Delete() 
# ADD:      New-Item -ItemType SymbolicLink -Path C:\SPI -Target "C:\Users\Chino\Dropbox (Reserve Membership)\SPI"


# FIRST SETUP THE PROGRAMDATA DIRECTORY JUNCTION
if (Test-Path -Path $sourceprogramdata) {

    Write-Warning "Folder '${sourceprogramdata}' already exist."

    if ($doUninstall) {
        $answer = "Y"
    }
    else {
        $answer = GetYN "Do you want to delete the valhalla programdata directory? (Y/N)"
    }

    if ($answer -eq "Y") {
        Write-Host "We are proceeding to delete the programdata directory" -ForegroundColor DarkBlue
        Write-Host "Removing the folder: '${sourceprogramdata}' ..." -ForegroundColor DarkBlue

        (Get-Item ${sourceprogramdata}).Delete() 
    }
    elseif ($answer -eq "N") {
        Write-Host "You selected NO, exiting ..." -ForegroundColor DarkBlue
        exit
    }

}
else { 
    Write-Warning "The folder '${sourceprogramdata}' does not exist."

    if (!$doUninstall) {
        Write-Host "We are proceeding to add a symbolic link to the programdata directory" -ForegroundColor DarkBlue
        New-Item -ItemType SymbolicLink -Path $sourceprogramdata -Target $targetprogramdata
    }
}

# THEN SETUP THE ROAMING DIRECTORY JUNCTION
if (Test-Path -Path $sourceroaming) {
    
    Write-Warning "Folder '${sourceroaming}' already exist."
    
    if ($doUninstall) {
        $answer = "Y"
    }
    else {
        $answer = GetYN "Do you want to delete the valhalla roaming directory? (Y/N)"
    }

    if ($answer -eq "Y") {
        Write-Host "We are proceeding to delete the roaming directory" -ForegroundColor DarkBlue
        Write-Host "Removing the folder: '${sourceroaming}' ..." -ForegroundColor DarkBlue
    
        (Get-Item ${sourceroaming}).Delete() 
    }
    elseif ($answer -eq "N") {
        Write-Host "You selected NO, exiting ..." -ForegroundColor DarkBlue
        exit
    }

}
else { 
    Write-Warning "The folder '${sourceroaming}' does not exist."

    if (!$doUninstall) {
        Write-Host "We are proceeding to add a symbolic link to the roaming directory" -ForegroundColor DarkBlue
        New-Item -ItemType SymbolicLink -Path $sourceroaming -Target $targetroaming
    }
}