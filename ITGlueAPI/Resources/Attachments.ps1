<#
.SYNOPSIS
    Attaches a file to the asset specified in the ID parameter.
.DESCRIPTION
    Attaches a file to the asset specified in the ID parameter. Returns the created object if successful. Can also be used to add multiple attachments to an asset in bulk.
.PARAMETER resource_type
    Specified the resource type to upload the attachment(s) to.
.PARAMETER resource_id
    Specifies the idetifier of the resource to upload the attachment(s) to.
.PARAMETER path
    Specifies the path to the file to be uploaded when uploading a single attachment.
.PARAMETER file_name
    Specifies the file name to be displayed on the asset view screen of the uploaded file when uploading a single attachment.
.PARAMETER multiplefiles
    Is a array of hashtables containing the path and file_name of multiple files to be uploaded.
    $multiplefiles = @(
        @{
            path = 'C:\path\to\file\first.png'
            file_name = 'first.png'
        },
        @{
            path = 'C:\path\to\file\second.exe'
            file_name = 'second.exe'
        }
    )
.EXAMPLE
    PS C:\> New-ITGlueAttachments -resource_type configurations -resource_id 22222222 -path 'C:\path\to\file\first.png' -file_name 'first.png'

    Uploads a single file from the path 'C:\path\to\file\first.png' to the configuration resource with ID 22222222 and names it 'first.png'.
.EXAMPLE
    PS C:\>$multiplefiles = @(
        @{
            path = 'C:\path\to\file\first.png'
            file_name = 'first.png'
        },
        @{
            path = 'C:\path\to\file\second.exe'
            file_name = 'second.exe'
        }
    )

    PS C:\>New-ITGlueAttachments -resource_type configurations -resource_id 22222222 -multiplefiles $multiplefiles

    Uploads a multiple files from the path 'C:\path\to\file\first.png' and 'C:\path\to\file\second.exe' to the configuration resource with ID 22222222 and names it 'first.png' and 'second.exe'.
.NOTES
    
.LINK
    https://api.itglue.com/developer#attachments-create
#>
function New-ITGlueAttachments {
    [CmdletBinding(DefaultParameterSetName = 'SingleAttachment')]
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = 'SingleAttachment')]
        [Parameter(Mandatory = $true, ParameterSetName = 'MultipleAttachments')]
        [ValidateSet( 'checklists', 'checklist_templates', 'configurations', 'contacts', 'documents', `
                'domains', 'locations', 'passwords', 'ssl_certificates', 'flexible_assets', 'tickets')]
        [string]$resource_type,

        [Parameter(Mandatory = $true, ParameterSetName = 'SingleAttachment')]
        [Parameter(Mandatory = $true, ParameterSetName = 'MultipleAttachments')]
        [int64]$resource_id,

        [Parameter(Mandatory = $true, ParameterSetName = 'SingleAttachment')]
        [string]$path,

        [Parameter(Mandatory = $true, ParameterSetName = 'SingleAttachment')]
        [string]$file_name,

        [Parameter(Mandatory = $true, ParameterSetName = 'MultipleAttachments')]
        [hashtable[]]$multiplefiles
    )

    $resource_uri = ('/{0}/{1}/relationships/attachments' -f $resource_type, $resource_id)

    if ($path -and $file_name) {
        $data = @{
            'data' = @{
                'type' = 'attachments'
                'attributes' = @{
                    'attachment' = @{
                        'content' = [Convert]::ToBase64String([IO.File]::ReadAllBytes($path))
                        'file_name' = $file_name
                    }
                }
            }
        }
    } elseif ($multiplefiles){
        $data = @{ 'data' = 
            @()
        }
        foreach ($file in $multiplefiles) {
            if ($file.ContainsKey('path') -and $file.ContainsKey('file_name')) {
                $data['data'] += @{
                    'type' = 'attachments'
                    'attributes' = @{
                        'attachment' = @{
                            'content' = [Convert]::ToBase64String([IO.File]::ReadAllBytes($file.path))
                            'file_name' = $file.file_name
                        }
                    }
                }
            } else {
                Throw "Hashtable doesn't contain necessary keys."
            }
        }
    }

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
    Updates the name of an existing attachment.
.DESCRIPTION
    Updates the details of an existing attachment. Only the attachment name that is displayed on the asset view screen can be changed. The original file_name can't be changed.
.PARAMETER resource_type
    Specified the resource type of the resource with the attachment to change the displayed name of.
.PARAMETER resource_id
    Specifies the idetifier of the resource with the attachment to change the displayed name of.
.PARAMETER attachment_id
    Specifies the idetifier of the attachment to change the displayed name of.
.PARAMETER new_name
    The new display name to change the attachment to.
.EXAMPLE
    PS C:\> Set-ITGlueAttachments -resource_type configurations -resource_id 22222222 -attachment_id 3333333 -new_name 'newname.png'

    Renames attachment with id 3333333 from configuration resource with id 22222222 to newname.png.
.LINK
    https://api.itglue.com/developer#attachments-update
#>
function Set-ITGlueAttachments {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]    
        [ValidateSet( 'checklists', 'checklist_templates', 'configurations', 'contacts', 'documents', `
                'domains', 'locations', 'passwords', 'ssl_certificates', 'flexible_assets', 'tickets')]
        [string]$resource_type,

        [Parameter(Mandatory = $true)]
        [int64]$resource_id,

        [Parameter(Mandatory = $true)]
        [int64]$attachment_id,

        [Parameter(Mandatory = $true)]
        $new_name

    )

    $resource_uri = ('/{0}/{1}/relationships/attachments/{2}' -f $resource_type, $resource_id, $attachment_id)

    $body = @{
        'data' = @{ 
            'type' = 'attachments'
            'attributes' = @{
                'name' = $new_name
            }
        }
    }

    $body = ConvertTo-Json -InputObject $body -Depth $ITGlue_JSON_Conversion_Depth

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
    Deletes one or more specified attachments.
.DESCRIPTION
    Deletes one or more specified attachments. Returns the deleted attachments and a 200 status code if successful.
.PARAMETER resource_type
    Specified the resource type of the resource with the attachment(s) to delete.
.PARAMETER resource_id
    Specifies the idetifier of the resource with the attachment(s) to delete.
.PARAMETER attachment_id
    Specifies the idetifier of the attachment(s) to delete.
.EXAMPLE
    PS C:\> Remove-ITGlueAttachments -resource_type configurations -resource_id 22222222 -attachment_id 3333333, 3333334, 3333335

    Removes attachments with ids 3333333, 3333334, 3333335 from configuration resource with id 22222222.
.LINK
    https://api.itglue.com/developer#attachments-bulk-destroy
#>
function Remove-ITGlueAttachments {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateSet( 'checklists', 'checklist_templates', 'configurations', 'contacts', 'documents', `
                'domains', 'locations', 'passwords', 'ssl_certificates', 'flexible_assets', 'tickets')]
        [string]$resource_type,

        [Parameter(Mandatory = $true)]
        [int64]$resource_id,

        [Parameter(Mandatory = $true)]
        [int64[]]$attachment_id
    )

    $resource_uri = ('/{0}/{1}/relationships/attachments' -f $resource_type, $resource_id)

    if (($attachment_id | Measure-Object).count -eq 1) {
        $data = @{
            data = @{
                'type' = 'attachments'
                'attributes' = @{
                    'id' = $attachment_id
                }
            }
        }
    } elseif (($attachment_id | Measure-Object).count -gt 1) {
        $data = @{ 'data' = 
            @()
        }
        foreach ($a_id in $attachment_id){
            $data['data'] += @{
                'type' = 'attachments'
                'attributes' = @{
                    'id' = $a_id
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
