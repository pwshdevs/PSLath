# <%=$PLASTER_PARAM_ModuleName%>

<%=$PLASTER_PARAM_Description%>

## Overview

## Installation

Install from the PowerShell Gallery:

```powershell
Install-PSResource -Name <%=$PLASTER_PARAM_ModuleName%>
```

For Windows PowerShell 5.1:

```powershell
Install-Module -Name <%=$PLASTER_PARAM_ModuleName%>
```

## Examples

```powershell
Import-Module <%=$PLASTER_PARAM_ModuleName%>
Get-HelloWorld
```

## Development

Bootstrap the development dependencies and run the complete test suite:

```powershell
./build.ps1 -Task Test -Bootstrap
```

The committed `requirements.psd1` contains the exact dependency versions that
passed together. The weekly GitHub Actions dependency canary temporarily tests
the newest versions on clean Windows runners under Windows PowerShell 5.1 and
PowerShell 7. When they pass, it updates the dependency pins, module version,
and changelog on a branch named `chore/dependency-canary-<version>` and opens a
pull request. Enable **Allow GitHub Actions to create and approve pull requests**
under the repository's Actions settings to allow that promotion step.

To publish a release only when the manifest version is newer than PSGallery, set
`PSGALLERY_API_KEY` and run:

```powershell
./tools/Publish-PSGallery.ps1
```

For CI publishing, configure `PSGALLERY_API_KEY` as a GitHub Actions secret, a
masked and protected GitLab CI/CD variable, an Azure Pipelines secret variable,
an AppVeyor secure environment variable, or a Jenkins credential with that name.
GitHub Actions, Azure Pipelines, AppVeyor, and Jenkins test both Windows
PowerShell 5.1 and PowerShell 7. GitLab tests PowerShell 7 by default; to enable
its PowerShell 5.1 job, configure a Windows runner tagged `windows` and set the
`ENABLE_WINDOWS_POWERSHELL_TESTS` CI/CD variable to `true`.
