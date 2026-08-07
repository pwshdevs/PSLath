function Get-LathTemplate {
    <#
    .SYNOPSIS
        Returns Lath's Plaster template
    .DESCRIPTION
        Returns Lath's Plaster template
    .EXAMPLE
        $template = Get-LathTemplate
        $template | New-LathModule

        Gets the Plaster template from the PSLath module and creates a new module with it
    .LINK
        New-LathModule
    #>
    [OutputType([PSCustomObject])]
    [cmdletbinding()]
    param()

    $moduleBase = $ExecutionContext.SessionState.Module.ModuleBase
    Get-PlasterTemplate -Path $moduleBase
}
