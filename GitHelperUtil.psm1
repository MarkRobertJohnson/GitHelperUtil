#Region 'PREFIX' 0
$ModuleRoot = $MyInvocation.MyCommand.ScriptBlock.Module.ModuleBase
. $ModuleRoot\Scripts\PreLoad.ps1 -ModuleRoot $ModuleRoot
#EndRegion 'PREFIX'
#Region '.\Private\Get-ModuleVariable.ps1' 0
function Get-ModuleVariable {
     [CmdletBinding()]
     param(
        [string]$Name = (throw "The Name parameter is required"),
        [switch]$DoNotAllowEmpty,
        [switch]$AllowNotSet,
        [AllowNull()][Object]$DefaultValue,
     [string]$ErrorMessage = "The '$Name' variable is not set.")

    $var = Get-Variable -Name $Name -ErrorAction SilentlyContinue
    

    #Case 1: The variable does not exist and no default value was set
    if(-not $DefaultValue -and ((-not $var -and -not $AllowNotSet))) {
        throw $ErrorMessage
    }

    #Case 2: The variable exists, but it has no value
    if($var -and -not $var.Value -and $DoNotAllowEmpty) {
        throw "The '$Name' variable is set, but it has an empty or null value and the '-DoNotAllowEmpty' switch was specified"
    }
    
    #Case 3: The variable does not exist, and the default was specified
    if($DefaultValue -and (-not $var -or -not $var.Value)) {
        Set-ModuleVariable -Name $Name -Value $DefaultValue -PassThru
    } else {
        $var.Value
    }
}
#EndRegion '.\Private\Get-ModuleVariable.ps1' 29
#Region '.\Private\Set-ModuleVariable.ps1' 0
function Set-ModuleVariable {
    [CmdletBinding(SupportsShouldProcess=$False)]
    param(
            
            [string]$Name,
            [object]$Value,
            [switch]$PassThru)

    Set-Variable -Force:$true -Name $Name -Value $Value -Visibility Public -Scope Script -WhatIf:$false
    if($PassThru) {
        $Value
    }

}
#EndRegion '.\Private\Set-ModuleVariable.ps1' 14
#Region '.\Public\Get-CodeChurn.ps1' 0
function Get-CodeChurn {
    param([string]$RepoDir,
        [string]$After,
        [string]$Before,
        [string]$GitArgs
    )
    <#
            .SYNOPSIS
            Get the code churn (number of time a file has been modified) for all files in a Git repository

            .PARAMETER RepoDir
            The repository location

            .PARAMETER After
            Optional parameter to specify to only look at code after a specified date (i.e. "after 2 months ago" or "1/1/2001")

            
            .PARAMETER Before
            Optional parameter to specify to only look at code before a specified date (i.e. "before 2 months ago" or "1/1/2001")

            
            .PARAMETER GitArgs
            Optional parameter to specify any additional arguments to pass to the "git log" command


    #>   
    if($After) {
        $afterArg = "--after='$After'"
    }
    if($Before) {
        $beforeArg = "--before='$Before'"
    }
    
    
    Invoke-GitCommand -Command "log --all -M -C --name-only --format='format:' $afterArg $beforeArg $GitArgs" -RepoDir $RepoDir | group-object | foreach {
        if($_.Name) {        
            [PSCustomObject]@{
                TimesModified = $_.Count;
                FileName = $_.Name
            }
        }
    }
}
#EndRegion '.\Public\Get-CodeChurn.ps1' 43
#Region '.\Public\Install-ChocoPackage.ps1' 0
function Install-ChocoPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$PackageId,
        [string]$ChocoArgs,
        [ValidateSet('upgrade','install')]
        [string]$InstallType = 'upgrade',
        [string]$Source
    )
    
    if($Source) {
        $Source = "-source $Source"
    }
    
    $chocoCmd = "choco.exe $InstallType $PackageId -y $Source $ChocoArgs"
    Invoke-Expression $chocoCmd
    if($LASTEXITCODE) {
        throw "Failed to install chocolatey package '$PackageId'"
    }
}
#EndRegion '.\Public\Install-ChocoPackage.ps1' 21
#Region '.\Public\Install-GitCommandline.ps1' 0
function Install-GitCommandline {
    [CmdletBinding()]
    param()
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if(-not $gitCmd) {
        Install-ChocoPackage -PackageId 'git.commandline' -ChocoArgs '--force'

        $gitCmd = Get-Command git
    }
    
    return $gitCmd.Path
}
#EndRegion '.\Public\Install-GitCommandline.ps1' 12
#Region '.\Public\Invoke-GitCommand.ps1' 0
function Invoke-GitCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Command, 
        [AllowNull()][int[]]$AllowedExitCodes,
        [AllowNull()][string]$RepoDir
    )
    

    $gitPath = Install-GitCommandline
    if(-not ($Command.Trim().ToLower().StartsWith('git'))) {
        $Command = ". `"$gitPath`" $Command"
    }
    Write-Host -fore green $Command
    try{
        if($RepoDir) {
            Push-Location -LiteralPath $RepoDir
        }
        $origPref = $ErrorActionPreference
        $ErrorActionPreference = 'continue'
        $result = ''
        Invoke-Expression -Command $Command -Verbose -ErrorVariable erroroutput  -ErrorAction SilentlyContinue -OutVariable output 2>&1 | Tee-Object -Variable result 
    } finally {
        
        if($RepoDir) {
            Pop-Location
        }
        $ErrorActionPreference = $origPref
        if($LASTEXITCODE -and $AllowedExitCodes -notcontains $LASTEXITCODE) {
            Write-Error ('LASTEXITCODE: ' + $LASTEXITCODE + ([Environment]::Newline) + $erroroutput + ([Environment]::Newline) + $result)
        }
        
    }
}
#EndRegion '.\Public\Invoke-GitCommand.ps1' 35
#Region 'SUFFIX' 0
$ModuleRoot = $MyInvocation.MyCommand.ScriptBlock.Module.ModuleBase
. $ModuleRoot\Scripts\PostLoad.ps1 -ModuleRoot $ModuleRoot
#EndRegion 'SUFFIX'
