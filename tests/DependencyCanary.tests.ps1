Describe 'Dependency canary promotion' {

    BeforeAll {
        $projectRoot = $env:BHProjectPath
        $updateHelper = Join-Path $projectRoot 'tools/Update-DependencyPins.ps1'
        $installedPester = Get-Module -Name Pester -ListAvailable |
            Sort-Object Version -Descending |
            Select-Object -First 1
        if (-not $installedPester) {
            throw 'Pester must be installed to test dependency canary promotion.'
        }
    }

    It 'Keeps PSLath rolling requirements separate from generated-module pins' {
        $rootRequirements = Import-PowerShellDataFile -LiteralPath (
            Join-Path $projectRoot 'requirements.psd1'
        )
        $templateRequirements = Import-PowerShellDataFile -LiteralPath (
            Join-Path $projectRoot 'PSLath/template/requirements.psd1'
        )
        $manifest = Import-PowerShellDataFile -LiteralPath (
            Join-Path $projectRoot 'PSLath/PSLath.psd1'
        )

        $rootRequirements.Pester.Version | Should -BeExactly 'latest'
        $rootRequirements.Pester.Parameters.SkipPublisherCheck | Should -BeTrue
        foreach ($entry in $templateRequirements.GetEnumerator()) {
            if ($entry.Key -eq 'PSDependOptions') {
                continue
            }
            $version = if ($entry.Value -is [string]) {
                $entry.Value
            } else {
                $entry.Value.Version
            }
            $version | Should -Not -BeExactly 'latest'
            $version -as [version] | Should -Not -BeNullOrEmpty
        }
        foreach ($requiredModule in $manifest.RequiredModules) {
            $requiredModule.RequiredVersion -as [version] | Should -Not -BeNullOrEmpty
            $requiredModule.ContainsKey('ModuleVersion') | Should -BeFalse
        }
    }

    It 'Temporarily rolls and then re-pins a generated module dependency set' {
        $fixtureRoot = Join-Path $TestDrive 'GeneratedProject'
        $moduleRoot = Join-Path $fixtureRoot 'CanaryFixture'
        New-Item -Path $moduleRoot -ItemType Directory -Force | Out-Null

        @"
@{
    PSDependOptions = @{ Target = 'CurrentUser' }
    Pester = '1.0.0'
}
"@ | Set-Content -LiteralPath (Join-Path $fixtureRoot 'requirements.psd1') -Encoding utf8
        @"
@{
    RootModule = 'CanaryFixture.psm1'
    ModuleVersion = '1.0.0'
    RequiredModules = @(
        @{ ModuleName = 'Pester'; RequiredVersion = '1.0.0' }
    )
}
"@ | Set-Content -LiteralPath (Join-Path $moduleRoot 'CanaryFixture.psd1') -Encoding utf8
        "exit 0" | Set-Content -LiteralPath (Join-Path $fixtureRoot 'build.ps1') -Encoding utf8
        "# Change Log`n`n## [1.0.0] Unreleased" |
            Set-Content -LiteralPath (Join-Path $fixtureRoot 'CHANGELOG.md') -Encoding utf8

        $result = & $updateHelper -ProjectRoot $fixtureRoot -ProposedVersion 1.1.0
        $requirements = Import-PowerShellDataFile -LiteralPath (
            Join-Path $fixtureRoot 'requirements.psd1'
        )
        $manifest = Import-PowerShellDataFile -LiteralPath (
            Join-Path $moduleRoot 'CanaryFixture.psd1'
        )
        $changelog = Get-Content -Raw -LiteralPath (Join-Path $fixtureRoot 'CHANGELOG.md')

        $result.Changed | Should -BeTrue
        $result.PinnedRequirementsPath | Should -BeExactly 'requirements.psd1'
        $requirements.Pester | Should -BeExactly ([string]$installedPester.Version)
        [string]$manifest.ModuleVersion | Should -BeExactly '1.1.0'
        [string]$manifest.RequiredModules[0].RequiredVersion |
            Should -BeExactly ([string]$installedPester.Version)
        $changelog | Should -Match '(?m)^## \[1\.1\.0\]'
        $changelog | Should -Match 'Validated and pinned `Pester`'
    }

    It 'Leaves a template project root rolling while updating its embedded pins' {
        $fixtureRoot = Join-Path $TestDrive 'TemplateProject'
        $moduleRoot = Join-Path $fixtureRoot 'TemplateFixture'
        $templateRoot = Join-Path $moduleRoot 'template'
        New-Item -Path $templateRoot -ItemType Directory -Force | Out-Null

        @"
@{
    PSDependOptions = @{ Target = 'CurrentUser' }
    Pester = 'latest'
}
"@ | Set-Content -LiteralPath (Join-Path $fixtureRoot 'requirements.psd1') -Encoding utf8
        @"
@{
    PSDependOptions = @{ Target = 'CurrentUser' }
    Pester = '1.0.0'
}
"@ | Set-Content -LiteralPath (Join-Path $templateRoot 'requirements.psd1') -Encoding utf8
        @"
@{
    RootModule = 'TemplateFixture.psm1'
    ModuleVersion = '1.0.0'
    RequiredModules = @(
        @{ ModuleName = 'Pester'; ModuleVersion = '1.0.0' }
    )
}
"@ | Set-Content -LiteralPath (Join-Path $moduleRoot 'TemplateFixture.psd1') -Encoding utf8
        "exit 0" | Set-Content -LiteralPath (Join-Path $fixtureRoot 'build.ps1') -Encoding utf8
        "# Change Log`n`n## [1.0.0] Unreleased" |
            Set-Content -LiteralPath (Join-Path $fixtureRoot 'CHANGELOG.md') -Encoding utf8

        $result = & $updateHelper -ProjectRoot $fixtureRoot -ProposedVersion 1.1.0
        $rootRequirements = Get-Content -Raw -LiteralPath (
            Join-Path $fixtureRoot 'requirements.psd1'
        )
        $templateRequirements = Import-PowerShellDataFile -LiteralPath (
            Join-Path $templateRoot 'requirements.psd1'
        )
        $manifestContent = Get-Content -Raw -LiteralPath (
            Join-Path $moduleRoot 'TemplateFixture.psd1'
        )
        $changelog = Get-Content -Raw -LiteralPath (Join-Path $fixtureRoot 'CHANGELOG.md')

        $result.Changed | Should -BeTrue
        $rootRequirements | Should -Match "Pester\s*=\s*'latest'"
        $templateRequirements.Pester | Should -BeExactly ([string]$installedPester.Version)
        $manifestContent | Should -Match 'RequiredVersion'
        $manifestContent | Should -Not -Match "ModuleVersion\s*=\s*'1\.0\.0'\s*}"
        $changelog | Should -Match '(?m)^## \[1\.1\.0\]'
    }
}
