function Invoke-IntuneRestoreDeviceEnrollmentConfiguration {
    <#
    .SYNOPSIS
    Restore Intune DeviceEnrollment Configurations
    
    .DESCRIPTION
    Restore Intune DeviceEnrollment Configurations from JSON files per DeviceEnrollment Configuration Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupDeviceEnrollmentConfigurations function
    
    .EXAMPLE
    Invoke-IntuneRestoreDeviceEnrollmentConfiguration -Path "C:\temp" -RestoreById $true
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Set the Microsoft Graph API endpoint
    if (-not ((Get-MSGraphEnvironment).SchemaVersion -eq $apiVersion)) {
        Update-MSGraphEnvironment -SchemaVersion $apiVersion -Quiet
        Connect-MSGraph -ForceNonInteractive -Quiet
    }

    # Get all DeviceEnrollment Configurations
    $DeviceEnrollmentConfigurations = Get-ChildItem -Path "$path\DeviceEnrollment Configurations" -File
    
    foreach ($DeviceEnrollmentConfiguration in $DeviceEnrollmentConfigurations) {
        $DeviceEnrollmentConfigurationContent = Get-Content -LiteralPath $DeviceEnrollmentConfiguration.FullName -Raw
        $DeviceEnrollmentConfigurationDisplayName = ($DeviceEnrollmentConfigurationContent | ConvertFrom-Json).displayName

        # Remove properties that are not available for creating a new configuration
        $requestBodyObject = $DeviceEnrollmentConfigurationContent | ConvertFrom-Json
        # Set SupportsScopeTags to $false, because $true currently returns an HTTP Status 400 Bad Request error.
        if ($requestBodyObject.supportsScopeTags) {
            $requestBodyObject.supportsScopeTags = $false
        }

        $requestBodyObject.PSObject.Properties | Foreach-Object {
            if ($null -ne $_.Value) {
                if ($_.Value.GetType().Name -eq "DateTime") {
                    $_.Value = (Get-Date -Date $_.Value -Format s) + "Z"
                }
            }
        }

        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, version | ConvertTo-Json -Depth 100

        # Restore the DeviceEnrollment Configuration
        try {
            $null = Invoke-MSGraphRequest -HttpMethod POST -Content $requestBody.toString() -Url "deviceManagement/DeviceEnrollmentConfigurations" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "DeviceEnrollment Configuration"
                "Name"   = $DeviceEnrollmentConfigurationDisplayName
                "Path"   = "DeviceEnrollment Configurations\$($DeviceEnrollmentConfiguration.Name)"
            }
        }
        catch {
            Write-Verbose "$DeviceEnrollmentConfigurationDisplayName - Failed to restore DeviceEnrollment Configuration" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}