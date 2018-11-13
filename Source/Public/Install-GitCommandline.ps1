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
