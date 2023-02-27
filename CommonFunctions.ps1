#
# Common Functions
#
# Import this file using relative path in other script files
# i.e. 
# .\CommonFunctions.ps1
#
# then you can use the functions normally like:
# $doUninstall = ParseBool $uninstall
# or
# $answer = GetYN "Do you want to delete the temp directory? (Y/N)"


# https://jonlabelle.com/snippets/view/powershell/get-the-current-os-platform-in-powershell
# use these methods like:
# if $(IsOnWindows)
# if (!$(IsOnMac)) 
# (!$(isOnLinux)) ? do something : do something else

Function isOnWindows {
    # This will work on 6.0 and later but is missing on
    # older versions
    if (Test-Path -Path 'variable:global:IsWindows') {
        return ParseBool (Get-Content -Path 'variable:global:IsWindows')
    }
    # This should catch older versions
    elseif (Test-Path -Path 'env:os') {
        return ParseBool ((Get-Content -Path 'env:os').StartsWith("Windows"))
    }
    # If all else fails
    else {
        return $false
    }
}
  
Function isOnLinux {
    if (Test-Path -Path 'variable:global:IsLinux') {
        return ParseBool (Get-Content -Path 'variable:global:IsLinux')
    }
  
    return $false
}
  
Function isOnMac {
    # The variable to test if you are on Mac OS changed from
    # IsOSX to IsMacOS. Because I have Set-StrictMode -Version Latest
    # trying to access a variable that is not set will crash.
    # So I use Test-Path to determine which exist and which to use.
    if (Test-Path -Path 'variable:global:IsMacOS') {
        return ParseBool (Get-Content -Path 'variable:global:IsMacOS')
    }
    elseif (Test-Path -Path 'variable:global:IsOSX') {
        return ParseBool (Get-Content -Path 'variable:global:IsOSX')
    }
    else {
        return $false
    }
}

Function ParseBool {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]  
        [String]$inputVal
    )
    
    switch -regex ($inputVal.Trim()) {
        "^(1|true|yes|y|on|enabled)$" { $true }

        default { $false }
    }
}

Function GetYN {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]  
        [String]$msg,

        [string]$BackgroundColor = "Black",
        [string]$ForegroundColor = "Green"
    )

    Do {
        # Write-Host -BackgroundColor $BackgroundColor -ForegroundColor $ForegroundColor -NoNewline "${msg} "
        Write-Host -ForegroundColor $ForegroundColor -NoNewline "${msg} "
        $answer = Read-Host
    }
    Until(($answer -eq "Y") -or ($answer -eq "N"))

    return $answer
}

Function GetElevation {
    # see https://www.powershellgallery.com/packages/Sudo/2.1.0/Content/Private%5CGetElevation.ps1
    Write-Host "Checking admin rights on platform: $($PSVersionTable.platform.ToString())" -ForegroundColor Blue

    # Windows check
    if ($PSVersionTable.PSEdition -eq "Desktop" -or $PSVersionTable.Platform -eq "Win32NT" -or $PSVersionTable.PSVersion.Major -le 5) {
        # get current user
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        
        # get current user context
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal $currentUser
  
        # get administrator role
        $administratorsRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

        if ($currentPrincipal.IsInRole($administratorsRole)) {
            Write-Host "Success. Script is running with Administrator privileges!" -ForegroundColor Green
            return $true
        }
        else {
            Write-Warning "$($currentUser.Name) is not an Administrator!"
            return $false
        }
    }
    
    # Unix, Linux and Mac OSX Check
    if ($PSVersionTable.Platform -eq "Unix") {
        if ($(whoami) -eq "root") {
            Write-Host "Success. Script is running with Administrator privileges!" -ForegroundColor Green
            return $true            
        }
        else {
            Write-Warning "$(whoami) is not an Administrator!"
            return $false
        }
    }
}

Function ExecuteElevation {
    [CmdletBinding()]
    param(
        # if using Mandatory=$true we get an error
        [Parameter(Position = 0)]
        [string[]]$argumentsList
    )

    Write-Host "Relaunching using arguments:" $argumentsList -ForegroundColor Blue

    # Windows check
    if ($PSVersionTable.PSEdition -eq "Desktop" -or $PSVersionTable.Platform -eq "Win32NT") {
        # Relaunch as an elevated process
        Start-Process pwsh -Verb runAs -ArgumentList $argumentsList
    }

    # Unix, Linux and Mac OSX Check
    if ($PSVersionTable.Platform -eq "Unix") {
        # Relaunch as an elevated process
        sudo pwsh $argumentsList
    }

    exit
}

Function Add-RegistryItem {
    <#
    .SYNOPSIS
    This function gives you the ability to create/change Windows registry keys and values. If you want to create a value but the key doesn't exist, it will create the key for you.

    .PARAMETER RegPath
    Path of the registry key to create/change

    .PARAMETER RegValue
    Name of the registry value to create/change

    .PARAMETER RegData
    The data of the registry value

    .PARAMETER RegType
    The type of the registry value. Allowed types: String,DWord,Binary,ExpandString,MultiString,None,QWord,Unknown. If no type is given, the function will use String as the type.

    .EXAMPLE 
    Add-RegistryItem -RegPath HKLM:\SomeKey -RegValue SomeValue -RegData 1111 -RegType DWord
    This will create the key SomeKey in HKLM:\. There it will create a value SomeValue of the type DWord with the data 1111.

    .NOTES
    Author: Dominik Britz
    Source: https://github.com/DominikBritz/Misc-PowerShell
    #>
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  
        $RegPath,

        $RegValue,
        $RegData,
        [ValidateSet('String', 'DWord', 'Binary', 'ExpandString', 'MultiString', 'None', 'QWord', 'Unknown')]
        $RegType = 'String'    
    )

    If (-not $RegValue) {
        If (-not (Test-Path $RegPath)) {
            Write-Verbose "The key $RegPath does not exist. Try to create it."
            Try {
                New-Item -Path $RegPath -Force
                Write-Verbose "Creation of $RegPath was successfull"
            }
            Catch {
                Write-Error -Message $_
            }
        }        
    }

    If ($RegValue) {
        If (-not (Test-Path $RegPath)) {
            Write-Verbose "The key $RegPath does not exist. Try to create it."
            Try {
                New-Item -Path $RegPath -Force
                Set-ItemProperty -Path $RegPath -Name $RegValue -Value $RegData -Type $RegType -Force
                Write-Verbose "Creation of $RegPath was successfull"
            }
            Catch {
                Write-Error -Message $_
            }
        }
        Else {
            Write-Verbose "The key $RegPath already exists. Try to set value"
            Try {
                Set-ItemProperty -Path $RegPath -Name $RegValue -Value $RegData -Type $RegType -Force
                Write-Verbose "Creation of $RegValue in $RegPath was successfull"           
            }
            Catch {
                Write-Error -Message $_
            }
        }
    }
}

Function Test-RegistryItem {  
  
    # Test-RegistryItem -RegPath "HKLM:\Software\Test" -RegValue "AKey"
    [CmdletBinding()]
    param (  
        [parameter(Mandatory = $true)]  
        [ValidateNotNullOrEmpty()]$RegPath,  
      
        [parameter(Mandatory = $true)]  
        [ValidateNotNullOrEmpty()]$RegValue  
    )  
      
    try {  
        Get-ItemProperty -Path $RegPath -Name $RegValue -ErrorAction Stop | Out-Null  
        return $true  
    } 
    catch {  
        return $false  
    }  
} 
    
Function Remove-RegistryItem {

    # Remove-RegistryItem -RegPath "HKLM:\Software\Test" -RegValue "AKey"
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        [String] $RegPath,

        [Parameter(Mandatory = $False)]
        [String] $RegValue = ""
    )
    
    If ((Test-Path $RegPath)) {
        Write-Verbose "The key $RegPath exists. Trying to delete ..."
    
        If ($RegValue -ne '') {
            # Delete the key Value
            $RIArgs = @{Path = $RegPath
                Name         = $RegValue
                Force        = $True
            }
            Remove-ItemProperty @RIArgs | Out-Null
        }
        Else {
            # Remove the Registry Path & Children!
            $RIArgs = @{Path = $RegPath
                Force        = $True
                Recurse      = $True
            }
            Remove-Item @RIArgs
        }
    
    }
    else {
        Write-Verbose "The key $RegPath does not exist."
    }
   
}

# Remove empty directories locally
Function Remove-EmptyFolder {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]  
        [String]$path,

        # Remove hidden files, like thumbs.db
        [Boolean]$removeHiddenFiles = $true,

        # Set to true to test the script
        [Boolean]$whatIf = $false
    )

    # Get hidden files or not. Depending on removeHiddenFiles setting
    $getHiddelFiles = !$removeHiddenFiles

    # Go through each subfolder, 
    Foreach ($subFolder in Get-ChildItem -Force -Literal $path -Directory) {
        # Call the function recursively
        Remove-EmptyFolder -path $subFolder.FullName $removeHiddenFiles $whatIf
    }
    
    # Get all child items
    $subItems = Get-ChildItem -Force:$getHiddelFiles -LiteralPath $path

    # If there are no items, then we can delete the folder
    # Exluce folder: If (($subItems -eq $null) -and (-Not($path.contains("DfsrPrivate")))) 
    If ($null -eq $subItems) {
        Write-Host "Removing empty folder '${path}'" -ForegroundColor Cyan
        Remove-Item -Force -Recurse:$removeHiddenFiles -LiteralPath $Path -WhatIf:$whatIf
    }
    else {
        Write-Warning "Not removing ${path} since it is not empty!"
    }
}

Function New-Folder-IfNotExist {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]  
        [String]$path,

        # Set to true to test the script
        [Boolean]$whatIf = $false
    )

    # Check that the folder exists
    if (Test-Path -Path $path -PathType Container) {
        Write-Host "Folder '${path}' already exist." -ForegroundColor Cyan
    }
    else {
        Write-Warning "The folder '${path}' does not exist."
        Write-Host "Creating the folder: '${path}' ..." -ForegroundColor Cyan
                
        New-Item -ItemType Directory -Force -Path $path -WhatIf:$whatIf
    }

}