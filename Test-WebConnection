<#
.SYNOPSIS
Tests to see if a Uri by Invoke-WebRequest -Method Head
.DESCRIPTION
Tests to see if a Uri by Invoke-WebRequest -Method Head
.LINK
https://osd.osdeploy.com/module/functions/webconnection
#>
function Test-WebConnection
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline)]
        # Uri to test
        [System.Uri]
        $Uri = 'google.com'
    )
    $Result = $false
    $Params = @{
        Method = 'Head'
        Uri = $Uri
        UseBasicParsing = $true
        Headers = @{'Cache-Control'='no-cache'}
    }

    try {
        Write-Verbose "Test-WebConnection OK: $Uri"
        Invoke-WebRequest @Params | Out-Null
        $Result = $true
    }
    catch {
        Write-Verbose "Test-WebConnection FAIL: $Uri"
        $Result = $false
    }
    finally {
            $Error.Clear()
    }
    If($Uri -notlike "*https://*"){
        $Params = @{
            Method = 'Head'
            Uri = "https://$Uri"
            UseBasicParsing = $true
            Headers = @{'Cache-Control'='no-cache'}
        }

        try {
            Write-Verbose "Test-WebConnection OK: $Uri"
            Invoke-WebRequest @Params | Out-Null
            $Result = $true
        }
        catch {
            Write-Verbose "Test-WebConnection FAIL: $Uri"
        }
        finally {
            $Error.Clear()
        }
    }
    Return $Result
}
