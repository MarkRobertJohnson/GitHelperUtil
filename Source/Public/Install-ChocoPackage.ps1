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