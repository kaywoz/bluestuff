##get-productkey.ps1
## displays OS productkey.
powershell “(Get-WmiObject -query ‘select * from SoftwareLicensingService’).OA3xOriginalProductKey”