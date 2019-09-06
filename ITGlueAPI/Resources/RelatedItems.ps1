<#
.SYNOPSIS
    Creates one or more related items.
.DESCRIPTION
    Creates a related item. Returns the created object if successful. Can also be used to add multiple related items to an asset in bulk.
.PARAMETER resource_type
    Specified the resource type of the resource to add the realted item(s) to.
.PARAMETER resource_id
    Specifies the idetifier of the resource to add the realted item(s) to.
.PARAMETER destination_id
    Specifies the identifier of the target resource to add as a related item.
.PARAMETER destination_type
    Specifies the resource type of the target resource to add as a related item.
.PARAMETER destination_note
    Specifies the optional note to give to the target resource being added as a related item.
.PARAMETER multiplerelateditems
    Specifies an array of hashtables containing the destination_id, destination_type, and optionally the note of multiple related items to be attached.
    $ri = @(
        @{
            destination_id = 22222223
            destination_type = 'Configuration'
        },
        @{
            destination_id = 22222224
            destination_type = 'Configuration'
            notes = 'This is a note.'
        }
    )
.EXAMPLE
    PS C:\> New-ITGlueRelatedItems -resource_type configurations -resource_id 22222222 -destination_id 22222223 -destination_type Configuration

    Adds a single realted item with id 22222223 and type Configuration to the resource with id 22222222 and type configurations.
.EXAMPLE
    PS C:\> New-ITGlueRelatedItems -resource_type configurations -resource_id 22222222 -destination_id 22222224 -destination_type Configuration -destination_note 'This is a note.'
    
    Adds a single realted item with id 22222224 and type Configuration with a note to the resource with id 22222222 and type configurations.
.EXAMPLE
    PS C:\> $MultipleRelatedItems = @(
        @{
            destination_id = 22222223
            destination_type = 'Configuration'
        },
        @{
            destination_id = 22222224
            destination_type = 'Configuration'
            notes = 'This is a note.'
        }
    )
    PS C:\> New-ITGlueRelatedItems -resource_type configurations -resource_id 22222222 -multiplerelateditems $MultipleRelatedItems

    Adds a multiple realted item with ids 22222223 and 22222224 and type Configuration with a note to the resource with id 22222222 and type configurations, one with a note and one without.
.LINK
    https://api.itglue.com/developer/#related-items-create
#>
function New-ITGlueRelatedItems {
    [CmdletBinding(DefaultParameterSetName = 'SingleRelatedItem')]
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = 'SingleRelatedItem')]
        [Parameter(Mandatory = $true, ParameterSetName = 'MultipleRelatedItems')]
        [ValidateSet( 'checklists', 'checklist_templates', 'configurations', 'contacts', 'documents', `
                'domains', 'locations', 'passwords', 'ssl_certificates', 'flexible_assets', 'tickets')]
        [string]$resource_type,

        [Parameter(Mandatory = $true, ParameterSetName = 'SingleRelatedItem')]
        [Parameter(Mandatory = $true, ParameterSetName = 'MultipleRelatedItems')]
        [Parameter(Mandatory = $true)]
        [int64]$resource_id,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'SingleRelatedItem')]
        [int64]$destination_id,

        [Parameter(Mandatory = $true, ParameterSetName = 'SingleRelatedItem')]
        [ValidateSet( 'User', 'Checklist', 'Checklist Template', 'Contact', 'Configuration', `
                'Datto Device', 'Document', 'Folder', 'Domain', 'Location', 'Organization', `
                'Password', 'SSL Certificate', 'Flexible Asset', 'Ticket')]
        [string]$destination_type,

        [Parameter(Mandatory = $false, ParameterSetName = 'SingleRelatedItem')]
        [string]$destination_note = '',

        [Parameter(Mandatory = $true, ParameterSetName = 'MultipleRelatedItems')]
        [hashtable[]]$multiplerelateditems
    )


    if ($destination_id -and $destination_type) {
        $data = @{
            'data' = @{
                'type' = 'related_items'
                'attributes' = @{
                    'destination_id' = $destination_id
                    'destination_type' = $destination_type
                    'notes' = $destination_note
                }
            }
        }
    } elseif ($multiplerelateditems) {
        $data = @{ 'data' = 
            @()
        }
        foreach ($relateditem in $multiplerelateditems) {
            if ($relateditem.ContainsKey('destination_id') -and $relateditem.ContainsKey('destination_type')) {
                $data['data'] += @{
                    'type' = 'related_items'
                    'attributes' = @{
                        'destination_id' = $relateditem.destination_id
                        'destination_type' = $relateditem.destination_type
                        'notes' = if ($relateditem.notes) { $relateditem.notes } else { '' }
                    }
                }
            } else {
                Throw "Hashtable doesn't contain necessary keys."
            }
        }
    }


    $resource_uri = ('/{0}/{1}/relationships/related_items' -f $resource_type, $resource_id)

    $body = ConvertTo-Json -InputObject $data -Depth $ITGlue_JSON_Conversion_Depth

    try {
        $ITGlue_Headers.Add('x-api-key', (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'N/A', $ITGlue_API_Key).GetNetworkCredential().Password)
        $rest_output = Invoke-RestMethod -method 'POST' -uri ($ITGlue_Base_URI + $resource_uri) -headers $ITGlue_Headers `
            -body $body -ErrorAction Stop -ErrorVariable $web_error
    } catch {
        Write-Error $_
    } finally {
        [void] $ITGlue_Headers.Remove('x-api-key') # Quietly clean up scope so the API key doesn't persist
    }

    $data = @{}
    $data = $rest_output 
    return $data
}

<#
.SYNOPSIS
    Updates the details of an existing related item.
.DESCRIPTION
    Updates the details of an existing related item. Only the related item notes that are displayed on the asset view screen can be changed.
.PARAMETER resource_type
    Specified the resource type of the resource to update the note of the realted item.
.PARAMETER resource_id
    Specifies the idetifier of the resource to update the note of the realted item.
.PARAMETER related_item_id
    Specifies the identifier of the related item of which to update the note.
.PARAMETER notes
    Specifies the new note to change of the related item.
.EXAMPLE
    PS C:\> Set-ITGlueRelatedItems -resource_type configurations -resource_id 22222222 -related_item_id 3333333 -notes 'New note.'

    Changes the note of the related item with id 3333333 attached to resource with id 22222222 and type configurations.
.LINK
    https://api.itglue.com/developer/#related-items-update
#>
function Set-ITGlueRelatedItems {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]    
        [ValidateSet( 'checklists', 'checklist_templates', 'configurations', 'contacts', 'documents', `
                'domains', 'locations', 'passwords', 'ssl_certificates', 'flexible_assets', 'tickets')]
        [string]$resource_type,

        [Parameter(Mandatory = $true)]
        [int64]$resource_id,

        [Parameter(Mandatory = $true)]
        [int64]$related_item_id,

        [Parameter(Mandatory = $true)]
        [string]$notes

    )

    $resource_uri = ('/{0}/{1}/relationships/related_items/{2}' -f $resource_type, $resource_id, $related_item_id)

    $data = @{
        'data' = @{
            'type' = 'related_items'
            'attributes' = @{
                'notes' = $notes
            }
        }
    }

    $body = ConvertTo-Json -InputObject $data -Depth $ITGlue_JSON_Conversion_Depth

    try {
        $ITGlue_Headers.Add('x-api-key', (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'N/A', $ITGlue_API_Key).GetNetworkCredential().Password)
        $rest_output = Invoke-RestMethod -method 'PATCH' -uri ($ITGlue_Base_URI + $resource_uri) -headers $ITGlue_Headers `
            -body $body -ErrorAction Stop -ErrorVariable $web_error
    } catch {
        Write-Error $_
    } finally {
        [void] $ITGlue_Headers.Remove('x-api-key') # Quietly clean up scope so the API key doesn't persist
    }

    $data = @{}
    $data = $rest_output 
    return $data
}

<#
.SYNOPSIS
    Deletes one or more specified related items.
.DESCRIPTION
    Deletes one or more specified related items. Returns the deleted related items and a 200 status code if successful.
.PARAMETER resource_type
    Specified the resource type of the resource with realted items to delete.
.PARAMETER resource_id
    Specifies the idetifier of the resource with realted items to delete.
.PARAMETER related_item_id
    Specifies the identifier of the related item(s) of which to delete.
.EXAMPLE
    PS C:\> Remove-ITGlueRelatedItems -resource_type configurations -resource_id 22222222 -related_item_id 3333333
    
    Deletes related item with id 3333333 from resource with id 22222222 and type configurations.
.EXAMPLE
    PS C:\> Remove-ITGlueRelatedItems -resource_type configurations -resource_id 22222222 -related_item_id 3333333, 3333334

    Deletes related items with id 3333333 and 3333334 from resource with id 22222222 and type configurations.
.LINK
    https://api.itglue.com/developer/#related-items-bulk-destroy
#>
function Remove-ITGlueRelatedItems {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]    
        [ValidateSet( 'checklists', 'checklist_templates', 'configurations', 'contacts', 'documents', `
                'domains', 'locations', 'passwords', 'ssl_certificates', 'flexible_assets', 'tickets')]
        [string]$resource_type,

        [Parameter(Mandatory = $true)]
        [int64]$resource_id,

        [Parameter(Mandatory = $true)]
        [int64[]]$related_item_id
    )

    $resource_uri = ('/{0}/{1}/relationships/related_items' -f $resource_type, $resource_id)

    if (($related_item_id | Measure-Object).count -eq 1) {
        $data = @{
            data = @{
                'type' = 'related_items'
                'attributes' = @{
                    'id' = $related_item_id
                }
            }
        }
    } elseif (($related_item_id | Measure-Object).count -gt 1) {
        $data = @{ 'data' = 
            @()
        }
        foreach ($r_id in $related_item_id){
            $data['data'] += @{
                'type' = 'related_items'
                'attributes' = @{
                    'id' = $r_id
                }
            }
        }
    }

    $body = ConvertTo-Json -InputObject $data -Depth $ITGlue_JSON_Conversion_Depth

    try {
        $ITGlue_Headers.Add('x-api-key', (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'N/A', $ITGlue_API_Key).GetNetworkCredential().Password)
        $rest_output = Invoke-RestMethod -method 'DELETE' -uri ($ITGlue_Base_URI + $resource_uri) -headers $ITGlue_Headers `
            -body $body -ErrorAction Stop -ErrorVariable $web_error
    } catch {
        Write-Error $_
    } finally {
        [void] $ITGlue_Headers.Remove('x-api-key') # Quietly clean up scope so the API key doesn't persist
    }

    $data = @{}
    $data = $rest_output 
    return $data
}
