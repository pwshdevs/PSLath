[cmdletbinding(DefaultParameterSetName = 'Task')]
param(
    # Build task(s) to execute
    [parameter(ParameterSetName = 'task', position = 0)]
    [ArgumentCompleter( {
            param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
            $psakeFile = './psakeFile.ps1'
            switch ($Parameter) {
                'Task' {
                    if ([string]::IsNullOrEmpty($WordToComplete)) {
                        Get-PSakeScriptTasks -buildFile $psakeFile | Select-Object -ExpandProperty Name
                    } else {
                        Get-PSakeScriptTasks -buildFile $psakeFile |
                            Where-Object { $_.Name -match $WordToComplete } |
                            Select-Object -ExpandProperty Name
                    }
                }
                Default {
                }
            }
        })]
    [string[]]$Task = 'default',
    # Bootstrap dependencies
    [switch]$Bootstrap,
    # List available build tasks
    [parameter(ParameterSetName = 'Help')]
    [switch]$Help,
    [pscredential]$PSGalleryApiKey,
    # Optional properties to pass to psake
    [hashtable]$Properties
)

$ErrorActionPreference = 'Stop'

function Initialize-ProjectModuleBuildEnvironment {
    param([string]$ProjectRoot)

    Set-BuildEnvironment -Force

    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
    $sourceRoot = Join-Path -Path $ProjectRoot -ChildPath 'src'
    $manifestCandidates = @(
        Get-ChildItem -LiteralPath $sourceRoot -Directory |
            ForEach-Object {
                $candidate = Join-Path -Path $_.FullName -ChildPath "$($_.Name).psd1"
                if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                    $candidate
                }
            }
    )
    if ($manifestCandidates.Count -ne 1) {
        throw "Expected one module manifest beneath $sourceRoot; found $($manifestCandidates.Count)."
    }

    $manifestPath = $manifestCandidates[0]
    $modulePath = Split-Path -Path $manifestPath -Parent
    $env:BHProjectPath = $ProjectRoot
    $env:BHProjectName = [System.IO.Path]::GetFileNameWithoutExtension($manifestPath)
    $env:BHModulePath = $modulePath
    $env:BHPSModulePath = $modulePath
    $env:BHPSModuleManifest = $manifestPath
}

# Bootstrap dependencies
if ($Bootstrap.IsPresent) {
    Get-PackageProvider -Name Nuget -ForceBootstrap | Out-Null
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    if (-not (Get-Module -Name PSDepend -ListAvailable)) {
        Install-Module -Name PSDepend -Repository PSGallery
    }
    Import-Module -Name PSDepend -Verbose:$false
    Invoke-PSDepend -Path './requirements.psd1' -Install -Import -Force -WarningAction SilentlyContinue
}

# Execute psake task(s)
$psakeFile = './psakeFile.ps1'
if ($Help.IsPresent) {
    Get-PSakeScriptTasks -buildFile $psakeFile  |
        Format-Table -Property Name, Description, Alias, DependsOn
} else {
    Initialize-ProjectModuleBuildEnvironment -ProjectRoot $PSScriptRoot
    $parameters = @{}
    if ($PSGalleryApiKey) {
        $parameters['galleryApiKey'] = $PSGalleryApiKey
    }
    Invoke-psake -buildFile $psakeFile -taskList $Task -nologo -parameters $parameters
    exit ( [int]( -not $psake.build_success ) )
}
