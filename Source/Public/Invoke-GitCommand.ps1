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
