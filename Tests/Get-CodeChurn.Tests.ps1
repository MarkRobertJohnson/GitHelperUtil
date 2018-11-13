$myModule = Import-Module (Get-ChildItem "$PSScriptRoot\..\Source\*.psm1" | Select-Object -ExpandProperty FullName -first 1) -force -PassThru


Describe 'Get-CodeChurn' {
    BeforeEach {
        $repoDir = "$PSScriptRoot\TestData\DummyRepo" 
        if(Test-Path $repoDir) {
            $null = del $repoDir -Recurse -Force
        }
        mkdir $repoDir -Force -ErrorAction SilentlyContinue
        Invoke-GitCommand -Command "init" -RepoDir $repoDir

        $files = @()
        #Create dummy files in the dummy git repo
        for($i = 0;$i -lt 4;$i++) {
            $fname = (Join-Path $repoDir "file${i}.txt")
            "BLAH$i" > $fname
            $files += $fname
            
        }  
         
        
        Invoke-GitCommand -Command "add `"*.txt`"" -RepoDir $repoDir
        Invoke-GitCommand -Command "commit -m `"Adding $($files.Length) dummy files`"" -RepoDir $repoDir
        
        #Perform multiple commits on each file, each file being modified the same number of 
        #   times as the position in the array (i.e. the 2nd element is modified 2 times)
        for($i = $files.Length - 1;$i -ge 0 ;$i--) {
            for($j = ($files.Length - 1); $j -ge $i; $j--) {
                gc $files[$j] -raw | out-string | Out-File -FilePath $files[$j] -Append
                
            }
            Invoke-GitCommand -Command "commit --all -m `"update $($files.Length - $i)`"" -RepoDir $repoDir
        }
    }

    It 'can compute code churn' {           
        $churn = Get-CodeChurn -RepoDir $repoDir 
        for($i = 0; $i -lt $churn.Length;$i++) {
            $churn[$i].TimesModified | Should Be ($i + 2)
        }
        
    }
    
}
