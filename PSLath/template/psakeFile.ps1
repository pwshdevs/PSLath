properties {
    # Set this to $true to create a module with a monolithic PSM1
    $PSBPreference.Build.CompileModule = $false
    $PSBPreference.Help.DefaultLocale = 'en-US'
    $PSBPreference.Test.OutputFile = 'out/testResults.xml'
}

# Run static analysis before Pester initializes its test runspaces. This avoids
# a PSScriptAnalyzer null-reference failure observed after Pester on PowerShell 7.6.4.
$PSBTestDependency = @('Analyze', 'Pester')

task Default -depends Test

task Test -FromModule PowerShellBuild -minimumVersion '0.8.2'

task Publish -FromModule PowerShellBuild -minimumVersion '0.8.2'
