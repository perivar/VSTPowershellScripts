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
    Write-Verbose "-Verbose flag found on Platform: $($PSVersionTable.Platform)"
}

# output if using -Debug
$Debug = [bool]$PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Debug")
if ($Debug) {
    Write-Debug "-Debug flag found on Platform: $($PSVersionTable.Platform)"
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
        '-NoExit'
        '-File'
        $(IsOnWindows) ? '"' + $MyInvocation.MyCommand.Definition + '"' : $MyInvocation.MyCommand.Definition
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
$sourceProgramData = Join-Path $environment.programData "Valhalla DSP, LLC"
$targetProgramData = Join-Path $environment.cloudHomeDir "Audio" "Audio Software" "Valhalla DSP, LLC"
$sourceRoaming = Join-Path $environment.appData "Valhalla DSP, LLC"
$targetRoaming = Join-Path $environment.cloudHomeDir "Audio" "Audio Software" "Valhalla DSP, LLC"

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
if (Test-Path -Path $sourceprogramdata -PathType Container) {

    Write-Warning "Folder '${sourceprogramdata}' already exist."

    if ($doUninstall) {
        $answer = "Y"
    }
    else {
        $answer = GetYN "Do you want to delete the valhalla programdata directory? (Y/N)"
    }

    if ($answer -eq "Y") {
        Write-Host "We are proceeding to delete the programdata directory" -ForegroundColor Cyan
        Write-Host "Removing the symbolic link to: '${sourceprogramdata}' ..." -ForegroundColor Cyan

        # remove the symbolic link
        (Get-Item ${sourceprogramdata}).Delete() 
    }
    elseif ($answer -eq "N") {
        Write-Host "You selected NO, exiting ..." -ForegroundColor Cyan
        exit
    }

}
else { 
    Write-Warning "The symbolic link to '${sourceprogramdata}' does not exist."

    if (!$doUninstall) {
        Write-Host "We are proceeding to add a symbolic link to the programdata directory" -ForegroundColor Cyan
        New-Item -ItemType SymbolicLink -Path $sourceprogramdata -Target $targetprogramdata
    }
}

# THEN SETUP THE ROAMING DIRECTORY JUNCTION
if (Test-Path -Path $sourceroaming -PathType Container) {
    
    Write-Warning "Folder '${sourceroaming}' already exist."
    
    if ($doUninstall) {
        $answer = "Y"
    }
    else {
        $answer = GetYN "Do you want to delete the valhalla roaming directory? (Y/N)"
    }

    if ($answer -eq "Y") {
        Write-Host "We are proceeding to delete the roaming directory" -ForegroundColor Cyan
        Write-Host "Removing the symbolic link to: '${sourceroaming}' ..." -ForegroundColor Cyan
    
        # remove the symbolic link
        (Get-Item ${sourceroaming}).Delete() 
    }
    elseif ($answer -eq "N") {
        Write-Host "You selected NO, exiting ..." -ForegroundColor Cyan
        exit
    }

}
else { 
    Write-Warning "The symbolic link to '${sourceroaming}' does not exist."

    if (!$doUninstall) {
        Write-Host "We are proceeding to add a symbolic link to the roaming directory" -ForegroundColor Cyan
        New-Item -ItemType SymbolicLink -Path $sourceroaming -Target $targetroaming
    }
}