##delete-pstranscripts

######make pstranscript dir and set dir to hidden
$sec_user = "$env:USERNAME@$env:USERDNSDOMAIN" ##-- testing purposes only, remove so as not to allow the user account access to the transcripts-folder.
$pstranscripts_dir = "C:\ProgramData\.pstranscripts\"

New-Item -ItemType directory -Force -Path $pstranscripts_dir | Out-Null -ErrorAction SilentlyContinue
Get-Item -Path $pstranscripts_dir | foreach {$_.Attributes = "Hidden"} -ErrorAction SilentlyContinue


$acl = Get-ACL -Path $pstranscripts_dir
$acl.SetAccessRuleProtection($true,$false)
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administrators","FullControl","ContainerInherit,ObjectInherit","None","Allow")
$acl.SetAccessRule($AccessRule)
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\SYSTEM","FullControl","ContainerInherit,ObjectInherit","None","Allow")
$acl.SetAccessRule($AccessRule)
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\Local Service","FullControl","ContainerInherit,ObjectInherit","None","Allow")
$acl.SetAccessRule($AccessRule)
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($sec_user,"FullControl","ContainerInherit,ObjectInherit","None","Allow")
$acl.SetAccessRule($AccessRule)
$acl | Set-Acl $pstranscripts_dir

######create sched tasks to clean pstranscripts
schtasks /create /RU "SYSTEM" /tn pstranscripts_cleanup /tr "C:\ProgramData\.pstranscripts\delete-pstranscripts.bat" /sc minute /mo 20

######set contents for delete-pstranscripts.bat
$content_file = "C:\ProgramData\.pstranscripts\delete-pstranscripts.bat"
Set-Content -Path $content_file -Value ':: Deletes all files older than runtime in C:\ProgramData\.pstranscripts\, and all folders older than 1d.'
Add-Content -Path $content_file -Value '::'
Add-Content -Path $content_file -Value '@ECHO OFF'
Add-Content -Path $content_file -Value 'C:\Windows\System32\forfiles.exe /S /D -0 /P "C:\ProgramData\.pstranscripts" /M "*.txt" /C "cmd /C del /Q @path"'
Add-Content -Path $content_file -Value 'C:\Windows\System32\forfiles.exe -p "C:\ProgramData\.pstranscripts" -d -1 -c "cmd /c IF @isdir == TRUE rd /S /Q @path"'
