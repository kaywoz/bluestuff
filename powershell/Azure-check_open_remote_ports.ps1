##Azure-openremotports.ps1

Connect-AzAccount
$subscriptionList = Get-AzSubscription
foreach ( $subscription in $subscriptionList) {
    Set-AzContext -Subscription $subscription | Out-Null
    Get-AzNetworkSecurityGroup | select -ExpandProperty securityrules  | Where-Object {$_.DestinationPortRange -in "22","3389" -and $_.SourceAddressPrefix -eq "*" -and $_.Description -notlike "Qualys" -and $_.Direction -eq "Inbound" -and $_.Access -eq "Allow"}| Export-Csv -NoTypeInformation "openremotports_azure_$(Get-Date -Uformat "%Y%m%d-%H%M%S").csv" -Append
 }
