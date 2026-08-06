BeforeAll {
    $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
    $builtManifestPath = Join-Path $env:BHProjectPath "Output\$($env:BHProjectName)\$($manifest.ModuleVersion)\$($env:BHProjectName).psd1"
    Import-Module -Name $builtManifestPath -Force -ErrorAction Stop
}

describe 'Get-LathTemplate' {
    it 'Returns the Lath template' {
        $t = Get-LathTemplate
        $t.psobject.TypeNames.Contains('System.Management.Automation.PSCustomObject') | Should -Be $true
    }
}
