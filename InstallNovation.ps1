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
$programData = [Environment]::GetFolderPath("CommonApplicationData") # $env:ProgramData
$programFilesx86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)") # ${Env:ProgramFiles(x86)}

Write-Host ""
Write-Host "Environment Variables:" -ForegroundColor Magenta
Write-Host "${cloudHomeEnvVar}: $cloudHomeDir" -ForegroundColor Magenta
Write-Host "programData: $programData" -ForegroundColor Magenta
Write-Host "programFilesx86: $programFilesx86" -ForegroundColor Magenta
Write-Host ""

#############################
# DEBUG WITH DUMMY VARIABLES
if ($Debug) {
    Write-Host "!!!!!! DEBUGGING WITH DUMMY VARIABLES !!!!!!!"  -ForegroundColor Red
    $cloudHomeDir = "/Users/perivar/OneDrive/"
    $programData = "/Users/perivar/Temp/programdata"
    $programFilesx86 = "/Users/perivar/Temp/programFilesx86"
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
$source = Join-Path "${programFilesx86}" "Novation"
$target = Join-Path "${cloudHomeDir}" "Audio" "Audio Software" "Novation"

Write-Host ""
Write-Host "Directory Paths:" -ForegroundColor Magenta
Write-Host "source: $source" -ForegroundColor Magenta
Write-Host "target: $target" -ForegroundColor Magenta
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

if (Test-Path -Path $source -PathType Container) {

    Write-Warning "Folder '${source}' already exist."

    if ($doUninstall) {
        $answer = "Y"
    }
    else {
        $answer = GetYN "Do you want to delete the source directory? (Y/N)"
    }

    if ($answer -eq "Y") {
        Write-Host "We are proceeding to delete the source directory" -ForegroundColor DarkBlue
        Write-Host "Removing the folder: '${source}' ..." -ForegroundColor DarkBlue

        (Get-Item ${source}).Delete() 
    }
    elseif ($answer -eq "N") {
        Write-Host "You selected NO, exiting ..." -ForegroundColor DarkBlue
        exit
    }

}
else { 
    Write-Warning "The folder '${source}' does not exist."

    if (!$doUninstall) {
        Write-Host "We are proceeding to add a symbolic link to the target directory" -ForegroundColor DarkBlue
        New-Item -ItemType SymbolicLink -Path $source -Target $target
    }
}

