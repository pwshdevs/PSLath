---
external help file: PSLath-help.xml
Module Name: PSLath
online version:
schema: 2.0.0
---

# Get-LathTemplate

## SYNOPSIS
Returns Lath's Plaster template

## SYNTAX

```
Get-LathTemplate [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns Lath's Plaster template

## EXAMPLES

### EXAMPLE 1
```
$template = Get-LathTemplate
$template | New-LathModule
```

Gets the Plaster template from the PSLath module and creates a new module with it

## PARAMETERS

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject
## NOTES

## RELATED LINKS

[New-LathModule]()

