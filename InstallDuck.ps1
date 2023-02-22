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
    $programFiles = "/Users/perivar/Temp/programfiles"
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
$dmProgramFiles = Join-Path "${programFiles}" "Devious Machines"
$sourceProgramFiles = Join-Path "${programFiles}" "Devious Machines" "Duck"
$targetProgramFiles = Join-Path "${cloudHomeDir}" "Audio" "Audio Software" "Devious Machines" "Duck" "ProgramFiles"

$dmProgramData = Join-Path "${programData}" "Devious Machines"
$sourceProgramData = Join-Path "${programData}" "Devious Machines" "Duck"
$targetProgramData = Join-Path "${cloudHomeDir}" "Audio" "Audio Software" "Devious Machines" "Duck" "ProgramData"

Write-Host ""
Write-Host "Directory Paths:" -ForegroundColor Magenta
Write-Host "dmProgramFiles: $dmProgramFiles" -ForegroundColor Magenta
Write-Host "sourceProgramFiles: $sourceProgramFiles" -ForegroundColor Magenta
Write-Host "targetProgramFiles: $targetProgramFiles" -ForegroundColor Magenta
Write-Host "dmProgramData: $dmProgramData" -ForegroundColor Magenta
Write-Host "sourceProgramData: $sourceProgramData" -ForegroundColor Magenta
Write-Host "targetProgramData: $targetProgramData" -ForegroundColor Magenta
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


# FIRST SETUP THE Program Files DIRECTORY JUNCTION
if (Test-Path -Path $sourceProgramFiles -PathType Container) {

    Write-Warning "Folder '${sourceProgramFiles}' already exist."

    if ($doUninstall) {
        $answer = "Y"
    }
    else {
        $answer = GetYN "Do you want to delete the Devious Machines Program Files Duck directory? (Y/N)"
    }

    if ($answer -eq "Y") {
        Write-Host "We are proceeding to delete the Devious Machines Program Files Duck Directory" -ForegroundColor DarkBlue
        Write-Host "Removing the folder: '${sourceProgramFiles}' ..." -ForegroundColor DarkBlue

        (Get-Item ${sourceProgramFiles}).Delete() 
    }
    elseif ($answer -eq "N") {
        Write-Host "You selected NO, exiting ..." -ForegroundColor DarkBlue
        exit
    }

}
else { 
    Write-Warning "The folder '${sourceProgramFiles}' does not exist."

    if (!$doUninstall) {

        # Check that the DeviousMachines folder exists
        if (Test-Path -Path $dmProgramFiles -PathType Container) {
            Write-Host "Folder '${dmProgramFiles}' already exist." -ForegroundColor DarkBlue
        }
        else {
            Write-Warning "The folder '${dmProgramFiles}' does not exist."
            Write-Host "Creating '${dmProgramFiles}' ..." -ForegroundColor DarkBlue
                    
            New-Item -ItemType Directory -Force -Path $dmProgramFiles
        }

        Write-Host "We are proceeding to add a symbolic link to the Devious Machines Program Files Duck Directory" -ForegroundColor DarkBlue
        New-Item -ItemType SymbolicLink -Path $sourceProgramFiles -Target $targetProgramFiles
    }
}

# THEN SETUP THE ProgramData DIRECTORY JUNCTION
if (Test-Path -Path $sourceProgramData -PathType Container) {
    
    Write-Warning "Folder '${sourceProgramData}' already exist."
    
    if ($doUninstall) {
        $answer = "Y"
    }
    else {
        $answer = GetYN "Do you want to delete the Devious Machines ProgramData Duck directory? (Y/N)"
    }

    if ($answer -eq "Y") {
        Write-Host "We are proceeding to delete the Devious Machines ProgramData Duck directory" -ForegroundColor DarkBlue
        Write-Host "Removing the folder: '${sourceProgramData}' ..." -ForegroundColor DarkBlue
    
        (Get-Item ${sourceProgramData}).Delete() 
    }
    elseif ($answer -eq "N") {
        Write-Host "You selected NO, exiting ..." -ForegroundColor DarkBlue
        exit
    }

}
else { 
    Write-Warning "The folder '${sourceProgramData}' does not exist."

    if (!$doUninstall) {
        # Check that the DeviousMachines folder exists
        if (Test-Path -Path $dmProgramData -PathType Container) {
            Write-Host "Folder '${dmProgramData}' already exist." -ForegroundColor DarkBlue
        }
        else {
            Write-Warning "The folder '${dmProgramData}' does not exist."
            Write-Host "Creating '${dmProgramData}' ..." -ForegroundColor DarkBlue
                            
            New-Item -ItemType Directory -Force -Path $dmProgramData
        }
                
        Write-Host "We are proceeding to add a symbolic link to the roaming directory" -ForegroundColor DarkBlue
        New-Item -ItemType SymbolicLink -Path $sourceProgramData -Target $targetProgramData
    }
}