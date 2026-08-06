# PSLath <img src="./media/lath.png" alt="Trowel"  height="8%" width="8%" style="float:right" align="right">

**Github**

[![GitHub Actions Status][github-actions-badge]][github-actions-build] [![GitHub Actions Status][github-actions-badge-publish]][github-actions-build] [![GitHub Actions Status][github-actions-badge-canary]][github-actions-build] [![GitHub Open Issues Status][github-open-issues-badge]][github-open-issues] [![GitHub Closed Issues Status][github-closed-issues-badge]][github-closed-issues] [![License][license-badge]][license]

**PSGallery**

[![PowerShell Gallery][psgallery-badge]][psgallery] [![PSGallery Version][psgallery-version-badge]][psgallery] [![PSGallery Playform][psgallery-platform-badge]][psgallery] [![PSGallery Playform][ps-desktop-badge]][psgallery]

> [!IMPORTANT]
> This is a rebuild of the [Stucco](https://github.com/devblackops/Stucco) Module with some various tweaks and bugfixes for personal use.
> Feel free to use also. You can view the differences and details by looking at [the commit changes](https://github.com/devblackops/Stucco/compare/main...pwshdevs:PSLath:main) and the [issues from devblackops/Stucco](https://github.com/devblackops/Stucco/issues).

## Contents
- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Contribution](#contribution)

***

## Overview

> [!TIP]
> PSLath is an **opinionated** [Plaster](https://github.com/PowerShellOrg/Plaster) template for building high-quality [PowerShell](https://github.com/PowerShell/PowerShell) modules.
> This template produces PowerShell projects according to a structure that I and many others in the PowerShell community use.
> Apart from the PowerShell module itself, this template creates project scaffolding that enables effective collaboration with the community.


## Features

- MIT, Apache, or Unlicense licensing options
- Changelog following [Keep a Changelog](http://keepachangelog.com/) guidelines with [Semantic Versioning](http://semver.org/)
- Optional [Code of Conduct](http://contributor-covenant.org)
- Optional [Read The Docs](https://readthedocs.org/) support for online documentation using [Mkdocs](https://www.mkdocs.org/)
- Optional [PlatyPS](https://github.com/PowerShell/platyPS) support for markdown-based help documentation
- Project dependency resolution using [PSDepend](https://github.com/RamblingCookieMonster/PSDepend)
- Reproducible generated projects with pinned build dependencies and a weekly rolling dependency canary
- [psake](https://github.com/psake/psake) tasks using [PowerShellBuild](https://github.com/psake/PowerShellBuild) for build / test automation
- [AppVeyor](https://www.appveyor.com/), [Azure Pipelines](https://azure.microsoft.com/en-us/services/devops/pipelines/) or [GitLab CI/CD](https://docs.gitlab.com/ee/ci/) for CI/CD
- GitHub templates for contributing, issues, and pull requests
- VSCode tasks

## Installation

Install from the [PowerShell Gallery]():

```powershell
Install-PSResource PSLath
```

or

```powershell
Install-Module -Name PSLath
```

## Usage

```powershell
$templateParameters = @{
    ModuleName   = 'MyModule'
    Description  = 'My PowerShell module'
    Version      = '0.1.0'
    FullName     = 'Your Name'
    License      = 'MIT'
    CoC          = 'No'
    MkDocs       = 'No'
    Classes      = 'Yes'
    PlatyPS      = 'Yes'
    devcontainer = 'Yes'
    CICD         = 'GitHubActions'
}

New-LathModule `
    -DestinationPath ./MyModule `
    -TemplateParameters $templateParameters `
    -Force `
    -NoLogo
```

Projects generated with GitHub Actions include a weekly dependency canary. It
temporarily tests the newest dependency versions on clean Windows runners under
Windows PowerShell 5.1 and PowerShell 7, then opens a versioned pull request only
when the validated pins change.
Enable **Allow GitHub Actions to create and approve pull requests** in the
repository's Actions settings before running the canary promotion job.

## Contribution

The goal of this project is help create common patterns for PowerShell module development.
Additional features or capabilities that benefit the community are welcome.

[github-actions-badge]: https://img.shields.io/github/actions/workflow/status/pwshdevs/PSLath/test.yaml?label=build&style=for-the-badge
[github-actions-badge-publish]: https://img.shields.io/github/actions/workflow/status/pwshdevs/PSLath/publish.yaml?label=publish&style=for-the-badge
[github-actions-badge-canary]: https://img.shields.io/github/actions/workflow/status/pwshdevs/PSLath/canary.yaml?label=publish&style=for-the-badge
[github-actions-build]: https://github.com/pwshdevs/PSLath/actions
[psgallery-badge]: https://img.shields.io/powershellgallery/dt/PSLath?label=downloads&style=for-the-badge
[psgallery]: https://www.powershellgallery.com/packages/PSLath
[psgallery-version-badge]: https://img.shields.io/powershellgallery/v/PSLath?label=version&style=for-the-badge
[license-badge]: https://img.shields.io/github/license/pwshdevs/PSLath?style=for-the-badge
[license]: https://raw.githubusercontent.com/pwshdevs/PSLath/main/LICENSE
[github-open-issues-badge]: https://img.shields.io/github/issues/pwshdevs/PSLath?style=for-the-badge
[github-closed-issues-badge]: https://img.shields.io/github/issues-closed/pwshdevs/PSLath?style=for-the-badge
[github-closed-issues]: https://github.com/pwshdevs/PSLath/issues?q=is%3Aissue%20state%3Aclosed
[github-open-issues]: https://github.com/pwshdevs/PSLath/issues
[psgallery-platform-badge]: https://img.shields.io/powershellgallery/p/PSLath?style=for-the-badge
[ps-desktop-badge]: https://img.shields.io/badge/powershell-5.1,_7.0+-blue?style=for-the-badge
[ps-core-badge]: https://img.shields.io/badge/powershell-5.1,_7.0+-blue?style=for-the-badge
