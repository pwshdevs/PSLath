Describe 'New-LathModule' {

    BeforeAll {
        $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
        $builtManifestPath = Join-Path $env:BHProjectPath "Output\$($env:BHProjectName)\$($manifest.ModuleVersion)\$($env:BHProjectName).psd1"
        Import-Module -Name $builtManifestPath -Force -ErrorAction Stop

        # Create the test module
        $testModuleName           = 'MyTestModule'
        $templateTestModulePath   = "TestDrive:/$testModuleName/withtemplate"
        $noTemplateTestModulePath = "TestDrive:/$testModuleName/notemplate"
        $params = @{
            Force           = $true
            NoLogo          = $true
            PassThru        = $true
            TemplateParameters = @{
                ModuleName   = $testModuleName
                Description  = 'My test module'
                Version      = '0.1.0'
                FullName     = 'Lath'
                License      = 'MIT'
                CoC          = 'No'
                MkDocs       = 'No'
                Classes      = 'Yes'
                PlatyPS      = 'Yes'
                devcontainer = 'Yes'
                CICD         = 'GitHubActions'
            }
        }
        $t = Get-LathTemplate

        $templateResult   = $t | New-LathModule -DestinationPath $templateTestModulePath @params | Select-Object -Last 1
        $noTemplateResult = New-LathModule -DestinationPath $noTemplateTestModulePath @params | Select-Object -Last 1

        $ciModules = @{}
        foreach ($provider in 'AppVeyor', 'AzurePipelines', 'GitLabCI', 'JenkinsCI', 'JenkinsCI-MultiStage') {
            $ciModuleName = "Test$($provider -replace '[^a-zA-Z0-9]', '')"
            $ciModulePath = "TestDrive:/$ciModuleName"
            $ciTemplateParameters = $params.TemplateParameters.Clone()
            $ciTemplateParameters.ModuleName = $ciModuleName
            $ciTemplateParameters.CICD = $provider
            $ciModules[$provider] = [pscustomobject]@{
                Path = $ciModulePath
                Result = New-LathModule `
                    -DestinationPath $ciModulePath `
                    -TemplateParameters $ciTemplateParameters `
                    -Force `
                    -NoLogo `
                    -PassThru |
                    Select-Object -Last 1
            }
        }
    }

    Context 'Template provided' {
        It 'Creates a module from a passed in template' {
            # Validate the module was created
            $templateResult.DestinationPath | Should -Exist
            $templateResult.Success         | Should -Be $true

            # Validate some module contents are there
            (Test-Path $templateTestModulePath/.devcontainer)            | Should -Be $true
            (Test-Path $templateTestModulePath/src/$testModuleName)      | Should -Be $true
            (Test-Path $templateTestModulePath/$testModuleName)          | Should -Be $false
        }
    }

    Context 'No template provided' {
        it 'Creates a module from the included template' {
            # Validate the module was created
            $noTemplateResult.DestinationPath | Should -Exist
            $noTemplateResult.Success         | Should -Be $true

            # Validate some module contents are there
            (Test-Path $NoTemplateTestModulePath/.devcontainer)            | Should -Be $true
            (Test-Path $NoTemplateTestModulePath/src/$testModuleName)      | Should -Be $true
            (Test-Path $NoTemplateTestModulePath/$testModuleName)          | Should -Be $false
        }
    }

    Context 'GitHub Actions' {
        It 'Creates separate GitHub test, publish, and dependency canary workflows' {
            $workflowPath = Join-Path $templateTestModulePath '.github/workflows'
            Test-Path -LiteralPath (Join-Path $workflowPath 'test.yml') -PathType Leaf | Should -BeTrue
            Test-Path -LiteralPath (Join-Path $workflowPath 'publish.yml') -PathType Leaf | Should -BeTrue
            Test-Path -LiteralPath (Join-Path $workflowPath 'canary.yml') -PathType Leaf | Should -BeTrue
            Test-Path -LiteralPath (Join-Path $workflowPath 'CI.yaml') | Should -BeFalse

            Get-Content -Raw -LiteralPath (Join-Path $workflowPath 'test.yml') |
                Should -Match 'actions/checkout@v6'
            Get-Content -Raw -LiteralPath (Join-Path $workflowPath 'test.yml') |
                Should -Match 'shell: powershell'
            Get-Content -Raw -LiteralPath (Join-Path $workflowPath 'publish.yml') |
                Should -Match 'secrets\.PSGALLERY_API_KEY'

            $publishTool = Join-Path $templateTestModulePath 'tools/Publish-PSGallery.ps1'
            Test-Path -LiteralPath $publishTool -PathType Leaf | Should -BeTrue
            Get-Content -Raw -LiteralPath $publishTool | Should -Match "ModuleName = 'MyTestModule'"

            foreach ($helper in 'Update-DependencyPins.ps1', 'Remove-BuildDependencies.ps1', 'Test-DependencyCanary.ps1') {
                Test-Path -LiteralPath (Join-Path $templateTestModulePath "tools/$helper") -PathType Leaf |
                    Should -BeTrue
            }
        }
    }

    Context 'Generated module loader' {
        It 'Imports with an empty Classes directory' {
            $classesPath = Join-Path $templateTestModulePath "src/$testModuleName/Classes"
            Get-ChildItem -LiteralPath $classesPath -Filter '*.ps1' -File | Remove-Item -Force

            Test-Path -LiteralPath $classesPath -PathType Container | Should -BeTrue
            @(Get-ChildItem -LiteralPath $classesPath -Filter '*.ps1' -File).Count | Should -Be 0

            $manifestPath = Join-Path $templateTestModulePath "src/$testModuleName/$testModuleName.psd1"
            { Import-Module -Name $manifestPath -Force -ErrorAction Stop } | Should -Not -Throw
            (Get-Command -Name Get-HelloWorld -Module $testModuleName -ErrorAction Stop).Name |
                Should -Be 'Get-HelloWorld'
            Remove-Module -Name $testModuleName -Force
        }

        It 'Imports with missing script directories' {
            foreach ($directory in 'Classes', 'Private', 'Public') {
                $directoryPath = Join-Path $noTemplateTestModulePath "src/$testModuleName/$directory"
                Remove-Item -LiteralPath $directoryPath -Recurse -Force
            }

            $manifestPath = Join-Path $noTemplateTestModulePath "src/$testModuleName/$testModuleName.psd1"
            { Import-Module -Name $manifestPath -Force -ErrorAction Stop } | Should -Not -Throw
            @(Get-Command -Module $testModuleName).Count | Should -Be 0
            Remove-Module -Name $testModuleName -Force
        }
    }

    Context 'Other CI providers' {
        It 'Creates an AppVeyor publish step' {
            $ciModules.AppVeyor.Result.Success | Should -BeTrue
            $content = Get-Content -Raw -LiteralPath (Join-Path $ciModules.AppVeyor.Path 'appveyor.yml')
            $content | Should -Match 'deploy_script:'
            $content | Should -Match 'Publish-PSGallery\.ps1'
        }

        It 'Creates an Azure Pipelines publish stage' {
            $ciModules.AzurePipelines.Result.Success | Should -BeTrue
            $content = Get-Content -Raw -LiteralPath (Join-Path $ciModules.AzurePipelines.Path 'azure-pipelines.yml')
            $content | Should -Match 'stage: Publish'
            $content | Should -Match 'Build\.SourceBranch'
            $content | Should -Match 'PSGALLERY_API_KEY'
            $content | Should -Match 'powershell: .*?-Task Test'
            $content | Should -Match 'pwsh: .*?-Task Test'
        }

        It 'Creates a GitLab publish job' {
            $ciModules.GitLabCI.Result.Success | Should -BeTrue
            $content = Get-Content -Raw -LiteralPath (Join-Path $ciModules.GitLabCI.Path '.gitlab-ci.yml')
            $content | Should -Match 'stage: publish'
            $content | Should -Match 'CI_DEFAULT_BRANCH'
            $content | Should -Match 'Publish-PSGallery\.ps1'
            $content | Should -Match 'ENABLE_WINDOWS_POWERSHELL_TESTS'
            $content | Should -Match 'powershell\.exe .*?-Task Test'
        }

        It 'Creates a Jenkins pipeline for Windows PowerShell and PowerShell 7' {
            $ciModules.JenkinsCI.Result.Success | Should -BeTrue
            $content = Get-Content -Raw -LiteralPath (Join-Path $ciModules.JenkinsCI.Path 'Jenkinsfile')
            $content | Should -Match "powershell '.+?-Task Test"
            $content | Should -Match "pwsh '.+?-Task Test"
            $content | Should -Match 'Publish-PSGallery\.ps1'
            $content | Should -Match "stage\('Publish'\)[\s\S]+?environment[\s\S]+?credentials\('PSGALLERY_API_KEY'\)"
        }

        It 'Creates a multistage Jenkins pipeline for both PowerShell editions' {
            $ciModules.'JenkinsCI-MultiStage'.Result.Success | Should -BeTrue
            $content = Get-Content -Raw -LiteralPath (Join-Path $ciModules.'JenkinsCI-MultiStage'.Path 'Jenkinsfile')
            $content | Should -Match 'Initialize \(Windows PowerShell 5\.1\)'
            $content | Should -Match 'Initialize \(PowerShell 7\)'
            $content | Should -Match 'Publish-PSGallery\.ps1'
        }
    }
}
