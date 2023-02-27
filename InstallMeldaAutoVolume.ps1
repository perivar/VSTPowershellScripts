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
$kerneltargetdir = Join-Path $environment.cloudHomeDir "Audio" "Audio Software" "MeldaProduction"
$kernelsourcedir = "C:\Windows"
$kernel = "MeldaProductionAudioPluginKernel.dll"
$kernel64 = "MeldaProductionAudioPluginKernel64.dll"

$source = Join-Path $environment.commonProgramFiles "VST3" "Shared"
$target = Join-Path $environment.cloudHomeDir "Audio" "VstPlugins VST3"
$meldasourcedir = Join-Path $environment.programData "MeldaProduction"
$meldatargetdir = Join-Path $environment.cloudHomeDir "Audio" "Audio Software" "MeldaProduction" "MeldaProduction"

Write-Host ""
Write-Host "Directory Paths:" -ForegroundColor Magenta
Write-Host "kerneltargetdir: $kerneltargetdir" -ForegroundColor Magenta
Write-Host "kernelsourcedir: $kernelsourcedir" -ForegroundColor Magenta
Write-Host "kernel: $kernel" -ForegroundColor Magenta
Write-Host "kernel64: $kernel64" -ForegroundColor Magenta

Write-Host "source: $source" -ForegroundColor Magenta
Write-Host "target: $target" -ForegroundColor Magenta
Write-Host "meldasourcedir: $meldasourcedir" -ForegroundColor Magenta
Write-Host "meldatargetdir: $meldatargetdir" -ForegroundColor Magenta
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
        Write-Host "We are proceeding to delete the source directory" -ForegroundColor Cyan
        Write-Host "Removing the symbolic link to: '${source}' ..." -ForegroundColor Cyan

        # remove the symbolic link
        (Get-Item ${source}).Delete() 
    }
    elseif ($answer -eq "N") {
        Write-Host "You selected NO, exiting ..." -ForegroundColor Cyan
        exit
    }

}
else { 
    Write-Warning "The symbolic link to '${source}' does not exist."

    if (!$doUninstall) {
        Write-Host "We are proceeding to add a symbolic link to the target directory" -ForegroundColor Cyan
        New-Item -ItemType SymbolicLink -Path $source -Target $target
    }
}


if (Test-Path -Path $meldasourcedir -PathType Container) {

    Write-Warning "Folder '${meldasourcedir}' already exist."

    if ($doUninstall) {
        $answer = "Y"
    }
    else {
        $answer = GetYN "Do you want to delete the source directory? (Y/N)"
    }

    if ($answer -eq "Y") {
        Write-Host "We are proceeding to delete the source directory" -ForegroundColor Cyan
        Write-Host "Removing the symbolic link to: '${meldasourcedir}' ..." -ForegroundColor Cyan

        # remove the symbolic link
        (Get-Item ${meldasourcedir}).Delete() 
    }
    elseif ($answer -eq "N") {
        Write-Host "You selected NO, exiting ..." -ForegroundColor Cyan
        exit
    }

}
else { 
    Write-Warning "The folder '${meldasourcedir}' does not exist."

    if (!$doUninstall) {
        Write-Host "We are proceeding to add a symbolic link to the target directory" -ForegroundColor Cyan
        New-Item -ItemType SymbolicLink -Path $meldasourcedir -Target $meldatargetdir
    }
}

# link up the kernels (note check for files using Leaf)
$kernelsource = "$kernelsourcedir\$kernel"
$kerneltarget = "$kerneltargetdir\$kernel"

if (Test-Path -Path $kernelsource -PathType Leaf) {

    Write-Warning "File '${kernelsource}' already exist."

    if ($doUninstall) {
        $answer = "Y"
    }
    else {
        $answer = GetYN "Do you want to delete the kernelsource file? (Y/N)"
    }

    if ($answer -eq "Y") {
        Write-Host "We are proceeding to delete the kernelsource file" -ForegroundColor Cyan
        Write-Host "Removing the file: '${kernelsource}' ..." -ForegroundColor Cyan

        # remove the symbolic link
        (Get-Item ${kernelsource}).Delete() 
    }
    elseif ($answer -eq "N") {
        Write-Host "You selected NO, exiting ..." -ForegroundColor Cyan
        exit
    }

}
else { 
    Write-Warning "The file '${kernelsource}' does not exist."

    if (!$doUninstall) {
        Write-Host "We are proceeding to add a symbolic link to the target file" -ForegroundColor Cyan
        New-Item -ItemType SymbolicLink -Path $kernelsource -Target $kerneltarget
    }
}

# link up the kernels (note check for files using Leaf)
$kernelsource64 = "$kernelsourcedir\$kernel64"
$kerneltarget64 = "$kerneltargetdir\$kernel64"

if (Test-Path -Path $kernelsource64 -PathType Leaf) {

    Write-Warning "File '${kernelsource64}' already exist."

    if ($doUninstall) {
        $answer = "Y"
    }
    else {
        $answer = GetYN "Do you want to delete the kernelsource64 file? (Y/N)"
    }

    if ($answer -eq "Y") {
        Write-Host "We are proceeding to delete the kernelsource64 file" -ForegroundColor Cyan
        Write-Host "Removing the file: '${kernelsource64}' ..." -ForegroundColor Cyan

        # remove the symbolic link
        (Get-Item ${kernelsource64}).Delete() 
    }
    elseif ($answer -eq "N") {
        Write-Host "You selected NO, exiting ..." -ForegroundColor Cyan
        exit
    }

}
else { 
    Write-Warning "The file '${kernelsource64}' does not exist."

    if (!$doUninstall) {
        Write-Host "We are proceeding to add a symbolic link to the target file" -ForegroundColor Cyan
        New-Item -ItemType SymbolicLink -Path $kernelsource64 -Target $kerneltarget64
    }
}
