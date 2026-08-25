function Invoke-CIPPStandardPasskeyDynamicMigrationOptOut {
    <#
    .FUNCTIONALITY
        Internal
    .COMPONENT
        (APIName) PasskeyDynamicMigrationOptOut
    .SYNOPSIS
        (Label) Opt Out of Automatic Passkey Migration
    .DESCRIPTION
        (Helptext) Sets or clears optOutSettings.passkeyDynamicMigration on the tenant's Authentication Methods Policy. When enabled, this excludes the tenant from Microsoft's automatic passkey enablement and Registration Campaign rollout for SMS/Voice users during the September 1, 2026 - February 1, 2027 window.
        (DocsDescription) Controls the temporary opt-out for Microsoft's automatic passkey migration of SMS/Voice-enabled users. This delays the Sept 1, 2026 auto-enablement and Registration Campaign rollout so you can plan communications and complete migration first. It does NOT change the Feb 1, 2027 retirement of Microsoft-provided SMS/Voice, which applies regardless of this setting. Ref: https://learn.microsoft.com/en-us/entra/identity/authentication/concept-sms-voice-retirement
    .NOTES
        CAT
            Entra (AAD) Standards
        TAG
        EXECUTIVETEXT
            Temporarily pauses Microsoft's automatic passkey nudge campaign for users still on SMS/Voice MFA, buying time to plan a smooth migration before the September 2026 rollout reaches this tenant. Does not affect the February 2027 SMS/Voice retirement deadline, which cannot be postponed.
        ADDEDCOMPONENT
            {"type":"switch","name":"standards.PasskeyDynamicMigrationOptOut.Enabled","label":"Opt out of automatic passkey migration (temporary, until Feb 1 2027)","defaultValue":true}
        IMPACT
            Low Impact
        ADDEDDATE
            2026-08-25
        POWERSHELLEQUIVALENT
            Update-MgBetaPolicyAuthenticationMethodPolicy -AuthenticationMethodsPolicy @{ optOutSettings = @{ passkeyDynamicMigration = \$true } }
        RECOMMENDEDBY
        DISABLEDFEATURES
            {"report":false,"warn":false,"remediate":false}
        UPDATECOMMENTBLOCK
            Run the Tools\Update-StandardsComments.ps1 script to update this comment block
    .LINK
        https://docs.cipp.app/user-documentation/tenant/standards/alignment/templates/available-standards
    #>
    param($Tenant, $Settings)

    $DesiredState = [bool]$Settings.Enabled

    try {
        $CurrentPolicy = New-GraphGetRequest -Uri 'https://graph.microsoft.com/beta/policies/authenticationMethodsPolicy' -tenantid $Tenant -AsApp $true
    } catch {
        $ErrorMessage = Get-CippException -Exception $_
        Write-LogMessage -API 'Standards' -tenant $Tenant -message "PasskeyDynamicMigrationOptOut: Could not retrieve authentication methods policy. Error: $($ErrorMessage.NormalizedError)" -sev Error -LogData $ErrorMessage
        return
    }

    $CurrentState = [bool]$CurrentPolicy.optOutSettings.passkeyDynamicMigration
    $IsCompliant = $CurrentState -eq $DesiredState

    if ($Settings.remediate -eq $true) {
        if ($IsCompliant) {
            Write-LogMessage -API 'Standards' -tenant $Tenant -message "PasskeyDynamicMigrationOptOut: Already set to '$DesiredState'." -sev Info
        } else {
            try {
                $Body = @{ optOutSettings = @{ passkeyDynamicMigration = $DesiredState } } | ConvertTo-Json -Depth 5 -Compress
                $null = New-GraphPostRequest -tenantid $Tenant -Uri 'https://graph.microsoft.com/beta/policies/authenticationMethodsPolicy' -Type patch -Body $Body -ContentType 'application/json'
                Write-LogMessage -API 'Standards' -tenant $Tenant -message "PasskeyDynamicMigrationOptOut: Set passkeyDynamicMigration to '$DesiredState' (was '$CurrentState')." -sev Info
            } catch {
                $ErrorMessage = Get-CippException -Exception $_
                Write-LogMessage -API 'Standards' -tenant $Tenant -message "PasskeyDynamicMigrationOptOut: Failed to update opt-out setting. Error: $($ErrorMessage.NormalizedError)" -sev Error -LogData $ErrorMessage
            }
        }
    }

    if ($Settings.alert -eq $true) {
        if ($IsCompliant) {
            Write-LogMessage -API 'Standards' -tenant $Tenant -message 'PasskeyDynamicMigrationOptOut: Compliant.' -sev Info
        } else {
            Write-StandardsAlert -message "PasskeyDynamicMigrationOptOut: passkeyDynamicMigration is '$CurrentState', expected '$DesiredState'." -object ([PSCustomObject]@{ Current = $CurrentState; Expected = $DesiredState }) -tenant $Tenant -standardName 'PasskeyDynamicMigrationOptOut' -standardId $Settings.standardId
            Write-LogMessage -API 'Standards' -tenant $Tenant -message "PasskeyDynamicMigrationOptOut: Not compliant. Current '$CurrentState', expected '$DesiredState'." -sev Info
        }
    }

    if ($Settings.report -eq $true) {
        Set-CIPPStandardsCompareField -FieldName 'standards.PasskeyDynamicMigrationOptOut' -CurrentValue $CurrentState -ExpectedValue $DesiredState -TenantFilter $Tenant
        Add-CIPPBPAField -FieldName 'PasskeyDynamicMigrationOptOut' -FieldValue $IsCompliant -StoreAs bool -Tenant $Tenant
    }
}
