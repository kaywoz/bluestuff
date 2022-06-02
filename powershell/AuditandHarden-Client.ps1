## to be executed as; powershell -nop -c "iex(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/kaywoz/bluestuff/main/powershell/AuditandHarden-Client.ps1')"

## sets som fairly basic audit policy via auditpol -> tbc
auditpol /set /subcategory:"Process Creation","File System","Registry" /success:enable /failure:enable

## sets other stuff
