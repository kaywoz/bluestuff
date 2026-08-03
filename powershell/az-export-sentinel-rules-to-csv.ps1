# ==========================================
# Sentinel Analytics Rule Export
# ==========================================

$ResourceGroup = "somename"
$WorkspaceName = "somename2"
$OutputFile = ".\SentinelRules.csv"

Write-Host "[+] Checking PowerShell version..." -ForegroundColor Cyan

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning "PowerShell 7+ is recommended."
}

# Check Az module
Write-Host "[+] Checking Az modules..." -ForegroundColor Cyan

$RequiredModules = @(
    "Az.Accounts",
    "Az.SecurityInsights"
)

foreach ($Module in $RequiredModules) {
    if (-not (Get-Module -ListAvailable -Name $Module)) {
        Write-Host "[+] Installing $Module..." -ForegroundColor Yellow

        Install-Module `
            -Name $Module `
            -Scope CurrentUser `
            -Repository PSGallery `
            -Force `
            -AllowClobber
    }
}

Import-Module Az.Accounts
Import-Module Az.SecurityInsights

# Check Azure connection
Write-Host "[+] Checking Azure authentication..." -ForegroundColor Cyan

try {
    $Context = Get-AzContext -ErrorAction Stop
}
catch {
    $Context = $null
}

if (-not $Context) {
    Write-Host "[+] Connecting to Azure..." -ForegroundColor Yellow
    Connect-AzAccount -ErrorAction Stop
}

# Let user choose subscription if multiple exist
$Subscriptions = Get-AzSubscription

if ($Subscriptions.Count -gt 1) {

    Write-Host ""
    Write-Host "Available subscriptions:" -ForegroundColor Green

    $Subscriptions |
        Select-Object Name, Id |
        Format-Table -AutoSize

    $SubscriptionName = Read-Host "Enter subscription name"

    Set-AzContext -Subscription $SubscriptionName | Out-Null
}

Write-Host ""
Write-Host "[+] Using subscription:" -ForegroundColor Green
(Get-AzContext).Subscription.Name

# Verify access to Sentinel workspace
Write-Host "[+] Testing Sentinel access..." -ForegroundColor Cyan

try {
    Get-AzSentinelAlertRule `
        -ResourceGroupName $ResourceGroup `
        -WorkspaceName $WorkspaceName `
        -ErrorAction Stop | Out-Null
}
catch {
    Write-Error "Unable to access Sentinel workspace. Check subscription, permissions, resource group, and workspace name."
    return
}

# Export rules
Write-Host "[+] Exporting analytics rules..." -ForegroundColor Cyan

Get-AzSentinelAlertRule `
    -ResourceGroupName $ResourceGroup `
    -WorkspaceName $WorkspaceName |
ForEach-Object {
    [PSCustomObject]@{
        RuleName       = $_.DisplayName
        RuleId         = $_.Name
        Severity       = $_.Severity
        Enabled        = $_.Enabled
        Kind           = $_.Kind
        QueryFrequency = $_.QueryFrequency
        QueryPeriod    = $_.QueryPeriod
        LastModified   = $_.LastModifiedUtc
        Tactics        = ($_.Tactic -join ';')
        Query          = ($_.Query -replace "`r?`n", ' ')
    }
} |
Export-Csv $OutputFile -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "[+] Export complete: $OutputFile" -ForegroundColor Green