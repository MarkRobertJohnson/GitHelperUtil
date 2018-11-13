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