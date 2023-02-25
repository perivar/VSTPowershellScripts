# set script parameters here
param (
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
        '-NoExit'
        '-File'
        '"' + $MyInvocation.MyCommand.Definition + '"'
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

# Include the GetEnvironment.ps1 file
. (Join-Path $PSScriptRoot GetEnvironment.ps1)
$environment = GetEnvironmentVariables "OneDrive"

# define paths
$sourceDirectoryx64 = Join-Path $environment.programFiles "Steinberg" "VSTPlugins" "Universal Audio"
$destinationDirectoryx64 = Join-Path $environment.programFiles "Steinberg" "VSTPlugins-Disabled" "Universal Audio"
$sourceDirectoryx86 = Join-Path $environment.programFilesx86 "Steinberg" "VSTPlugins" "Universal Audio"
$destinationDirectoryx86 = Join-Path $environment.programFilesx86 "Steinberg" "VSTPlugins-Disabled" "Universal Audio"

Write-Host ""
Write-Host "Directory Paths:" -ForegroundColor Magenta
Write-Host "sourceDirectoryx64: $sourceDirectoryx64" -ForegroundColor Magenta
Write-Host "destinationDirectoryx64: $destinationDirectoryx64" -ForegroundColor Magenta
Write-Host "sourceDirectoryx86: $sourceDirectoryx86" -ForegroundColor Magenta
Write-Host "destinationDirectoryx86: $destinationDirectoryx86" -ForegroundColor Magenta
Write-Host ""

# Make sure we can find the exclude file
$fileExcludeListName = "UADPluginsToKeep.txt"
$fileExcludeListPath = Join-Path $PSScriptRoot $fileExcludeListName
$fileExcludeList = Get-Content $fileExcludeListPath

#Write-Host $fileExcludeList -ForegroundColor Cyan

function MoveFilesExceptRecursively ($sourceDirectory, $destinationDirectory, $fileExcludeList) {
    # Create destinationDirectory if not exists
    if (-not (Test-Path -Path $destinationDirectory)) {
        New-Item -Path $destinationDirectory -ItemType Directory | Out-Null
    }

    #region move files (does support recursive folders)
    $files = Get-ChildItem $sourceDirectory -File -Recurse -Exclude $fileExcludeList

    foreach ($f in $files) {    
        Write-Host "Moving '$($f.FullName)' ..." -ForegroundColor Cyan

        $destinationPath = Join-Path $destinationDirectory $f.FullName.Substring($sourceDirectory.length)
        #Write-Host "destinationPath: $destinationPath" -ForegroundColor Magenta

        # Move file and force (overwrite if already exist) 
        #Move-Item -Path $f -Destination $destinationPath -Force
        Move-Item -Path $f -Destination $destinationDirectory -Force
    } 
    #endregion

}

Write-Host "Cleaning up $sourceDirectoryx64"
MoveFilesExceptRecursively $sourceDirectoryx64 $destinationDirectoryx64 $fileExcludeList

Write-Host "Cleaning up $sourceDirectoryx86"
MoveFilesExceptRecursively $sourceDirectoryx86 $destinationDirectoryx86 $fileExcludeList
