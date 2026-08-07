Describe 'PSLath continuous integration' {

    BeforeAll {
        $projectRoot = $env:BHProjectPath

        function Get-NormalizedContent {
            param([string]$LiteralPath)

            (Get-Content -Raw -LiteralPath $LiteralPath).Replace("`r`n", "`n").TrimEnd()
        }
    }

    It 'Uses the generated GitHub test workflow as its own test workflow' {
        $rootWorkflow = Get-NormalizedContent -LiteralPath (Join-Path $projectRoot '.github/workflows/test.yml')
        $templateWorkflow = Get-NormalizedContent -LiteralPath (Join-Path $projectRoot 'src/PSLath/template/cicd/github-test.yml')

        $rootWorkflow | Should -BeExactly $templateWorkflow
    }

    It 'Uses the generated GitHub publish workflow as its own publish workflow' {
        $rootWorkflow = Get-NormalizedContent -LiteralPath (Join-Path $projectRoot '.github/workflows/publish.yml')
        $templateWorkflow = Get-NormalizedContent -LiteralPath (Join-Path $projectRoot 'src/PSLath/template/cicd/github-publish.yml')

        $rootWorkflow | Should -BeExactly $templateWorkflow
    }

    It 'Uses the generated dependency canary workflow as its own canary workflow' {
        $rootWorkflow = Get-NormalizedContent -LiteralPath (Join-Path $projectRoot '.github/workflows/canary.yml')
        $templateWorkflow = Get-NormalizedContent -LiteralPath (Join-Path $projectRoot 'src/PSLath/template/cicd/github-canary.yml')

        $rootWorkflow | Should -BeExactly $templateWorkflow
    }

    It 'Uses generated copies of the dependency canary helpers' {
        foreach ($helper in 'Update-DependencyPins.ps1', 'Remove-BuildDependencies.ps1', 'Test-DependencyCanary.ps1') {
            $rootHelper = Get-NormalizedContent -LiteralPath (Join-Path $projectRoot "tools/$helper")
            $templateHelper = Get-NormalizedContent -LiteralPath (Join-Path $projectRoot "src/PSLath/template/tools/$helper")

            $rootHelper | Should -BeExactly $templateHelper
        }
    }

    It 'Keeps rolling dependencies at the PSLath root and pins generated-module dependencies' {
        $rootRequirements = Import-PowerShellDataFile -LiteralPath (
            Join-Path $projectRoot 'requirements.psd1'
        )
        $templateRequirements = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'src/PSLath/template/requirements.psd1')

        $rootRequirements.Pester.Version | Should -BeExactly 'latest'
        $rootRequirements.Pester.Parameters.SkipPublisherCheck | Should -BeTrue
        $templateRequirements | Should -Not -Match "Version\s*=\s*'latest'"
    }

    It 'Preserves inbox Pester 3 while cleaning newer Pester versions' {
        $cleanupHelper = Get-Content -Raw -LiteralPath (
            Join-Path $projectRoot 'tools/Remove-BuildDependencies.ps1'
        )

        $cleanupHelper | Should -Match '\$preservedPesterMajorVersion\s*=\s*3'
        $cleanupHelper | Should -Match 'Version\.Major\s*-ne\s*\$preservedPesterMajorVersion'
    }

    It 'Runs and verifies the generated module from its own project root' {
        $testHelper = Get-Content -Raw -LiteralPath (
            Join-Path $projectRoot 'tools/Test-DependencyCanary.ps1'
        )

        $testHelper | Should -Match 'Push-Location -LiteralPath \$Path'
        $testHelper | Should -Match '\$env:GITHUB_WORKSPACE\s*=\s*\$Path'
        $testHelper | Should -Match 'The generated module build was not found'
    }

    It 'Promotes canaries through a versioned bot branch and pull request' {
        $workflow = Get-Content -Raw -LiteralPath (Join-Path $projectRoot '.github/workflows/canary.yml')

        $workflow | Should -Not -Match 'shell:\s*\$\{\{\s*matrix\.'
        $workflow | Should -Match "if: steps\.resolve\.outputs\.changed == 'true'"
        $workflow | Should -Match "validate:[\s\S]+?if: needs\.resolve\.outputs\.changed == 'true'"
        $workflow | Should -Match "if: matrix\.edition == 'powershell-7'"
        $workflow | Should -Match "if: matrix\.edition == 'windows-powershell'"
        $workflow | Should -Match 'chore/dependency-canary-\$env:PROPOSED_VERSION'
        $workflow | Should -Match 'pull-requests:\s*write'
        $workflow | Should -Match 'needs\.validate\.result == ''success'''
    }

    It 'Uses a rendered copy of the generated conditional publishing helper' {
        $rootHelper = Get-NormalizedContent -LiteralPath (Join-Path $projectRoot 'tools/Publish-PSGallery.ps1')
        $templateHelper = Get-NormalizedContent -LiteralPath (Join-Path $projectRoot 'src/PSLath/template/tools/Publish-PSGallery.ps1')
        $renderedTemplateHelper = $templateHelper.Replace('<%=$PLASTER_PARAM_ModuleName%>', 'PSLath')

        $rootHelper | Should -BeExactly $renderedTemplateHelper
    }

    It 'Skips PSGallery publication successfully when no API key is configured' {
        $publishHelper = Join-Path $projectRoot 'tools/Publish-PSGallery.ps1'
        $hadApiKey = Test-Path -LiteralPath Env:PSGALLERY_API_KEY
        $originalApiKey = $env:PSGALLERY_API_KEY
        try {
            Remove-Item -LiteralPath Env:PSGALLERY_API_KEY -ErrorAction SilentlyContinue
            $decision = & $publishHelper -PassThru

            $decision.ShouldPublish | Should -BeFalse
            $decision.SkipReason | Should -BeExactly 'MissingApiKey'
        } finally {
            if ($hadApiKey) {
                $env:PSGALLERY_API_KEY = $originalApiKey
            } else {
                Remove-Item -LiteralPath Env:PSGALLERY_API_KEY -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Exposes the PowerShellBuild Publish task' {
        Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'psakeFile.ps1') |
            Should -Match "Task Publish -FromModule PowerShellBuild -minimumVersion '0\.8\.2'"
    }

    It 'Runs ScriptAnalyzer before Pester in both build definitions' {
        foreach ($buildFile in 'psakeFile.ps1', 'src/PSLath/template/psakeFile.ps1') {
            Get-Content -Raw -LiteralPath (Join-Path $projectRoot $buildFile) |
                Should -Match '\$PSBTestDependency = @\(''Analyze'', ''Pester''\)'
        }
    }

    It 'Seeds PowerShellBuild with the nested src module manifest' {
        foreach ($buildFile in 'build.ps1', 'src/PSLath/template/build.ps1') {
            $content = Get-Content -Raw -LiteralPath (Join-Path $projectRoot $buildFile)
            $content | Should -Match "ChildPath 'src'"
            $content | Should -Match '\$env:BHPSModuleManifest\s*=\s*\$manifestPath'
        }
    }
}
