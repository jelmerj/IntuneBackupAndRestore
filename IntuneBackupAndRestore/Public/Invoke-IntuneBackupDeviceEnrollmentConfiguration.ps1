function Invoke-IntuneBackupDeviceEnrollmentConfiguration {
    <#
    .SYNOPSIS
    Backup Intune DeviceEnrollment Configuration
    
    .DESCRIPTION
    Backup Intune DeviceEnrollment Configurations as JSON files per DeviceEnrollment Configuration to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupDeviceEnrollmentConfiguration -Path "C:\temp"
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

    # Create folder if not exists
    if (-not (Test-Path "$Path\DeviceEnrollment Configurations")) {
        $null = New-Item -Path "$Path\DeviceEnrollment Configurations" -ItemType Directory
    }

    # Get all App Protection Policies
    $DeviceEnrollmentConfigurations = Get-IntuneDeviceEnrollmentConfiguration | Get-MSGraphAllPages

    foreach ($DeviceEnrollmentConfiguration in $DeviceEnrollmentConfigurations) {
        $fileName = ($DeviceEnrollmentConfiguration.id).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $DeviceEnrollmentConfiguration | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\DeviceEnrollment Configurations\$fileName.json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "DeviceEnrollment Configuration"
            "Name"   = $DeviceEnrollmentConfiguration.displayName
            "Path"   = "DeviceEnrollment Configurations\$fileName.json"
        }
    }
}

