@{
    RootModule        = 'PSLath.psm1'
    ModuleVersion     = '1.0.1'
    GUID              = '0412383c-1e98-431d-9e55-a95a2c0635d6'
    Author            = 'PwshDevs'
    CompanyName       = 'PwshDevs'
    Copyright         = '(c) PwshDevs. All rights reserved.'
    Description       = 'An opinionated Plaster template for high-quality PowerShell modules'
    PowerShellVersion = '5.1'
    RequiredModules   = @(
        @{
            ModuleName      = 'BuildHelpers'
            RequiredVersion = '2.0.16'
        }
        @{
            ModuleName      = 'Plaster'
            RequiredVersion = '2.1.5'
        }
        @{
            ModuleName      = 'psake'
            RequiredVersion = '5.0.4'
        }
        @{
            ModuleName      = 'PowerShellBuild'
            RequiredVersion = '0.8.2'
        }
    )
    FunctionsToExport = @(
        'Get-LathTemplate'
        'New-LathModule'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Extensions   = @(
                @{
                    Module         = 'Plaster'
                    MinimumVersion = '2.1.3'
                    Details        = @{
                        TemplatePaths = @('.')
                    }
                }
            )
            Tags         = @('Plaster', 'Module', 'Template', 'PSEdition_Core', 'PSEdition_Desktop', 'Windows', 'Linux', 'MacOS')
            LicenseUri   = 'https://raw.githubusercontent.com/pwshdevs/PSLath/main/LICENSE'
            ProjectUri   = 'https://github.com/pwshdevs/PSLath'
            IconUri      = 'https://raw.githubusercontent.com/pwshdevs/PSLath/main/media/lath.png'
            ReleaseNotes = 'https://raw.githubusercontent.com/pwshdevs/PSLath/main/CHANGELOG.md'
        }
    }
}
