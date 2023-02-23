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

# Include the GetEnvironment.ps1 file
. (Join-Path $PSScriptRoot GetEnvironment.ps1)
$environment = GetEnvironmentVariables "OneDrive"

# define paths
$nicommon = Join-Path $environment.commonProgramFilesx86 "Native Instruments"
$sourcecommon = Join-Path $environment.commonProgramFilesx86 "Native Instruments" "Massive"
$targetcommon = Join-Path $environment.cloudHomeDir "Audio" "Audio Software" "Native Instruments" "Massive"
$nipresets = Join-Path $environment.userDocuments "Native Instruments"
$nimassivepresets = Join-Path $environment.userDocuments "Native Instruments" "Massive"
$sourcepresets = Join-Path $environment.userDocuments "Native Instruments" "Massive" "Sounds"
$targetpresets = Join-Path $environment.cloudHomeDir "Audio" "Presets" "Native Instruments Massive Presets"

Write-Host ""
Write-Host "Directory Paths:" -ForegroundColor Magenta
Write-Host "nicommon: $nicommon" -ForegroundColor Magenta
Write-Host "sourcecommon: $sourcecommon" -ForegroundColor Magenta
Write-Host "targetcommon: $targetcommon" -ForegroundColor Magenta
Write-Host "nipresets: $nipresets" -ForegroundColor Magenta
Write-Host "nimassivepresets: $nimassivepresets" -ForegroundColor Magenta
Write-Host "sourcepresets: $sourcepresets" -ForegroundColor Magenta
Write-Host "targetpresets: $targetpresets" -ForegroundColor Magenta
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


# FIRST SETUP THE COMMON DIRECTORY JUNCTION
if (Test-Path -Path $sourcecommon -PathType Container) {

    Write-Warning "Folder '${sourcecommon}' already exist."

    if ($doUninstall) {
        $answer = "Y"
    }
    else {
        $answer = GetYN "Do you want to delete the ni common massive directory? (Y/N)"
    }

    if ($answer -eq "Y") {
        Write-Host "We are proceeding to delete the ni common massive directory" -ForegroundColor DarkBlue
        Write-Host "Removing the folder: '${sourcecommon}' ..." -ForegroundColor DarkBlue

        (Get-Item ${sourcecommon}).Delete() 
    }
    elseif ($answer -eq "N") {
        Write-Host "You selected NO, exiting ..." -ForegroundColor DarkBlue
        exit
    }

}
else { 
    Write-Warning "The folder '${sourcecommon}' does not exist."

    if (!$doUninstall) {
        # Check that the Native Instrument common folder exists
        If (-not (Test-Path $nicommon -PathType Container)) {
            Write-Warning "The folder '${nicommon}' does not exist."

            Write-Host "We are proceeding to add ${nicommon}" -ForegroundColor DarkBlue
            New-Item -ItemType Directory -Force -Path $nicommon
        }
        else {
            Write-Host "OK. Native Instruments common folder already exists." -ForegroundColor Green
        }

        Write-Host "We are proceeding to add a symbolic link to the programdata directory" -ForegroundColor DarkBlue
        New-Item -ItemType SymbolicLink -Path $sourcecommon -Target $targetcommon
    }
}

# THEN SETUP THE PRESET DIRECTORY JUNCTION
if (Test-Path -Path $sourcepresets -PathType Container) {
    
    Write-Warning "Folder '${sourcepresets}' already exist."
    
    if ($doUninstall) {
        $answer = "Y"
    }
    else {
        $answer = GetYN "Do you want to delete the ni massive presets directory? (Y/N)"
    }

    if ($answer -eq "Y") {
        Write-Host "We are proceeding to delete the presets directory" -ForegroundColor DarkBlue
        Write-Host "Removing the folder: '${sourcepresets}' ..." -ForegroundColor DarkBlue
    
        (Get-Item ${sourcepresets}).Delete() 
    }
    elseif ($answer -eq "N") {
        Write-Host "You selected NO, exiting ..." -ForegroundColor DarkBlue
        exit
    }

}
else { 
    Write-Warning "The folder '${sourcepresets}' does not exist."

    if (!$doUninstall) {

        # Check that the Native Instrument preset folder exists
        If (-not (Test-Path $nipresets -PathType Container)) {
            Write-Warning "The folder '${nipresets}' does not exist."
        
            Write-Host "We are proceeding to add ${nipresets}" -ForegroundColor DarkBlue
            New-Item -ItemType Directory -Force -Path $nipresets
        }
        else {
            Write-Host "OK. Native Instruments preset folder already exists." -ForegroundColor Green
        }
                
        # Check that the Native Instrument Massive preset folder exists
        If (-not (Test-Path $nimassivepresets -PathType Container)) {
            Write-Warning "The folder '${nimassivepresets}' does not exist."
        
            Write-Host "We are proceeding to add ${nimassivepresets}" -ForegroundColor DarkBlue
            New-Item -ItemType Directory -Force -Path $nimassivepresets
        }
        else {
            Write-Host "OK. Native Instruments Massive preset folder already exists." -ForegroundColor Green
        }

        Write-Host "We are proceeding to add a symbolic link to the roaming directory" -ForegroundColor DarkBlue
        New-Item -ItemType SymbolicLink -Path $sourcepresets -Target $targetpresets
    }
}