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
$regPath = "HKCU:\Software\Tailored Noise\Sausage Fattener"
$regValue = "InstallLocation" 
$regData = Join-Path $environment.cloudHomeDir "Audio" "VstPlugins (x64)" "Saturation (Console Tape Tube)" "Sausage Fattener"

Write-Host ""
Write-Host "Data:" -ForegroundColor Magenta
Write-Host "regPath: $regPath" -ForegroundColor Magenta
Write-Host "regValue: $regValue" -ForegroundColor Magenta
Write-Host "regData: $regData" -ForegroundColor Magenta
Write-Host ""

if (Test-RegistryItem -RegPath $regPath -RegValue $regValue) {

    Write-Warning "Registry Path '${regPath}' already exist."

    if ($doUninstall) {
        $answer = "Y"
    }
    else {
        $answer = GetYN "Do you want to delete the Registry Path? (Y/N)"
    }

    if ($answer -eq "Y") {       
        # Removing Registry Path                 
        Write-Host "We are proceeding to delete Registry Path" -ForegroundColor Cyan

        # https://woshub.com/how-to-access-and-manage-windows-registry-with-powershell/
        # To remove all items in the reg key (but not the key itself)
        # Remove-Item –Path "HKLM:\Software\Novation\*" –Recurse
        # Remove-RegistryItem -RegPath "HKLM:\Software\Novation\*"
        Remove-RegistryItem -RegPath $regPath
        
        Write-Host "Please re-run this script." -ForegroundColor Cyan
    }
    elseif ($answer -eq "N") {
        Write-Host "You selected NO, exiting ..." -ForegroundColor Cyan
        exit
    }

}
else { 
    Write-Warning "The Registry Path '${regPath}' does not exist."

    if (!$doUninstall) {
        # Adding Registry Path 
        Write-Host "We are proceeding to add Registry Path" -ForegroundColor Cyan

        Add-RegistryItem -RegPath $regPath -RegValue $regValue -RegData $regData -RegType String    
    }
}
