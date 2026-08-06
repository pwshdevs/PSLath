@{
    PSDependOptions = @{
        Target = 'CurrentUser'
    }
    'Pester' = @{
        Version = 'latest'
        Parameters = @{
            SkipPublisherCheck = $true
        }
    }
    'psake' = 'latest'
    'BuildHelpers' = 'latest'
    'Plaster' = 'latest'
    'PowerShellBuild' = 'latest'
    'PSScriptAnalyzer' = 'latest'
}
