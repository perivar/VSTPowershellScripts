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
$source = Join-Path $environment.programFiles "Novation"
$target = Join-Path $environment.cloudHomeDir "Audio" "Audio Software" "Novation"

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
        Write-Host "We are proceeding to delete the source directory" -ForegroundColor Cyan
        Write-Host "Removing the symbolic link to: '${source}' ..." -ForegroundColor Cyan

        # remove the symbolic link
        (Get-Item ${source}).Delete() 

        # Removing registry keys                 
        Write-Host "We are proceeding to delete registry keys" -ForegroundColor Cyan

        # https://woshub.com/how-to-access-and-manage-windows-registry-with-powershell/
        # To remove all items in the reg key (but not the key itself)
        # Remove-Item –Path "HKLM:\Software\Novation\*" –Recurse
        # Remove-RegistryItem -RegPath "HKLM:\Software\Novation\*"
        Remove-RegistryItem -RegPath "HKLM:\Software\Novation\BassStation"
        Remove-RegistryItem -RegPath "HKLM:\Software\Novation\V-Station"
        
        Write-Host "Please re-run this script." -ForegroundColor Cyan
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

        # Adding registry keys 
        Write-Host "We are proceeding to add registry keys" -ForegroundColor Cyan

        # Add Novation to the 32 bit registry (WOW6432Node)
        Add-RegistryItem -RegPath "HKLM:\Software\WOW6432Node\Novation\BassStation" -RegValue "InstallDir" -RegData "C:\Program Files\Novation\Bass Station" -RegType String
        Add-RegistryItem -RegPath "HKLM:\Software\WOW6432Node\Novation\V-Station" -RegValue "InstallDir" -RegData "C:\Program Files\Novation\V-Station" -RegType String
    }
}

