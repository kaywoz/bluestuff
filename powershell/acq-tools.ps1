<#
    .Purpose
    The purpose of this code is to provide a mass-import of backup repositories

    .Dependencies
    VBR PowerShell modules installed
    1x CSV file called 'RepositoryList.csv' that contains three columns, the Name column, the Folder column, and the Type column, stored within the same directory as the PowerShell script
    Notes about Parameters:
    Name: This is a string that will label the repository name within VBR
    Description: This is a string that will populate the Description field within VBR for this repository
    Folder: This is a string that must contain a folder path
    Type: This is a VBR Repository type, valid values here are:
        WinLocal
        LinuxLocal
        CifsShare
        ExaGrid
        DataDomain
        HPStoreOnceIntegration
        Quantum
        Nfs
        Infinidat
        Fujitsu
        HPStoreOnceCloudBank
        Hardened

 #>

 
<#PSScriptInfo

.VERSION 

.GUID 

.AUTHOR 

.COMPANYNAME 

.COPYRIGHT 

.TAGS

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
    
.PRIVATEDATA

#>

<#
.SYNOPSIS
    
.DESCRIPTION
    
#>


Write-Host -ForegroundColor darkblue "@@@@@@@@        @@@@@@@@    @@@@@@@@@@@@@      @@@@@@@  @@@@@@@@@@                   @@@@@@@  @@@@@@
>> @@@@@@@@       @@@@@@@@   @@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@@@
>>  @@@@@@@@     @@@@@@@@  @@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@       @@@       @@@@@@@@@@@@@@@
>>  @@@@@@@@     @@@@@@@  @@@@@@@@@    @@@@@@@@  @@@@@@@@@@@@  @@@@@@@      @@@@@@@      @@@@@@@@@@@@@
>>   @@@@@@@    @@@@@@@  @@@@@@@@@  @@@@@@@@@@   @@@@@@@@@     @@@@@@      @@@@@@@@       @@@@@@@
>>   @@@@@@@@  @@@@@@@@  @@@@@@@@@@@@@@@@@@@@@   @@@@@@@@      @@@@@       @@@@@@@@       @@@@@@
>>   @@@@@@@@ @@@@@@@@   @@@@@@@@@@@@@@@@@@     @@@@@@@@      @@@@@@      @@@@@@@@@       @@@@@
>>    @@@@@@@ @@@@@@@   @@@@@@@@@@@@@@@         @@@@@@@@      @@@@@@      @@@@@@@@@      @@@@@
>>    @@@@@@@@@@@@@@     @@@@@@@@               @@@@@@@@      @@@@@@      @@@@@@@@       @@@@@
>>     @@@@@@@@@@@@      @@@@@@@@@     @@@@@@   @@@@@@@@      @@@@@@       @@@@@@      @@@@@@@
>>     @@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@ @@@@@@@@@      @@@@@@@       @@@       @@@@@@@@
>>      @@@@@@@@@          @@@@@@@@@@@@@@@@@@  @@@@@@@@      @@@@@@@@@               @@@@@@@@
>>      @@@@@@@@             @@@@@@@@@@@@@     @@@@@@@@      @@@@@@@@                @@@@@@@@          "



##checks
# check ps execution policy, interrogate and set as original when done.
write-host "fixing executionpolicy" -ForegroundColor Green
$default_executionpolicy = Get-ExecutionPolicy
Set-executionpolicy -ExecutionPolicy unrestricted -Force

# check if running as admin
write-host "checking admin" -ForegroundColor Green
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isadmintrue = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

##vars
write-host "setting vars" -ForegroundColor Green
$temp_path = "$env:TEMP\venor_v0rpal\forensics\"
$uuid = (Get-WmiObject -Class Win32_ComputerSystemProduct).UUID +"_"+(Get-Date -Format "yyyyMMddhhmm")
$work_path = "c:\venor_v0rpal"
$drop_path = "c:\venor_v0rpal.zip"

#1 dir make
write-host "making dirs" -ForegroundColor Green
rmdir "$temp_path" -force -Recurse -ErrorAction SilentlyContinue
rmdir "$drop_path" -force -Recurse -ErrorAction SilentlyContinue
mkdir "$temp_path"
#mkdir "$work_path"
mkdir "$temp_path\system"
mkdir "$temp_path\userinfo"
mkdir "$temp_path\networkinfo"
mkdir "$temp_path\fileprocessinfo"
mkdir "$temp_path\files"
mkdir "$temp_path\ramcapture"

## manage external tools
write-host "fixing tools" -ForegroundColor Green
Expand-Archive $drop_path -DestinationPath C:\ -Force

#2 acquire

## system
write-host "starting system acquisition" -ForegroundColor Green
systeminfo >> systeminfo.txt
$lastactivityview_path = "$work_path\lastactivityview\LastActivityView.exe"
$lastactivityview_args = "/stab $temp_path\system\lastactivityview.csv"
Start-Process $lastactivityview_path -ArgumentList $lastactivityview_args
ForEach ($NameSpace in "root\subscription","root\default") { get-wmiobject -namespace $NameSpace -query "select * from __EventConsumer" >> $temp_path\system\wmi.txt} 
Get-WmiObject win32_product | select Name, Vendor, Version, Caption | Out-File $temp_path\system\wmi_software.txt
Get-WindowsDriver -All -Online | select Driver, OriginalFileName, Date, Version | Out-File $temp_path\system\wmi_drivers.txt
Get-WmiObject Win32_Service | select Name, DisplayName, Description, PathName, StartName, ServiceType | Out-File $temp_path\system\wmi_services.txt
get-psdrive | Out-File $temp_path\system\psdrives.txt
$autoruns_path = "$work_path\SysinternalsSuite\autorunsc64.exe"
$autoruns_args = "-o $temp_path\system\autoruns.txt -c -a *"
Start-Process -NoNewWindow $autoruns_path -ArgumentList $autoruns_args # >> $temp_path\system\autorunsc.txt


##userinfo
write-host "starting userstuff" -ForegroundColor Green
net user | Out-File $temp_path\userinfo\local_users.txtls
net localgroup administrators | Out-File $temp_path\userinfo\local_admins.txt 

##network
write-host "starting networkstuff" -ForegroundColor Green
nbtstat.exe -c | Out-File $temp_path\networkinfo\nbtstat.txt
nbtstat.exe -S | Out-File $temp_path\networkinfo\nbtstat.txt
netstat.exe -anb | Out-File $temp_path\networkinfo\netstat_anb_results.txt
ipconfig /all | Out-File $temp_path\networkinfo\ipsettings.txt
ipconfig /displaydns | Out-File $temp_path\networkinfo\dns_cache.txt
netstat -anob | Out-File $temp_path\networkinfo\open_network_connections.txt
netstat -rn | Out-File $temp_path\networkinfo\routing_tables.txt
arp -a | Out-File $temp_path\networkinfo\arp.txt
Get-NetTCPConnection | select local*,remote*,state, owningprocess,@{Name="Process";Expression={(Get-Process -Id $_.OwningProcess).ProcessName}} | ft | Out-File $temp_path\networkinfo\net_tcp.txt
net sessions | Out-File $temp_path\networkinfo\netbios_sessions.txt

##fileprocessinfo
write-host "starting fileprocessstuff" -ForegroundColor Green
Get-ChildItem -Attributes Hidden $HOME -Recurse -ErrorAction SilentlyContinue  | select Name, Length, LastAccessTime, LastWriteTime, Directory | ft -AutoSize | Out-File $temp_path\fileprocessinfo\hidden_files_directories.txt
tasklist /V | Out-File $temp_path\fileprocessinfo\processes.txt
tasklist /M | Out-File $temp_path\fileprocessinfo\dlls.txt
tasklist /SVC | Out-File  $temp_path\fileprocessinfo\service_processess.txt

##files
write-host "skipping filesstuff for now" -ForegroundColor Yellow
##robocopy -zb $env:windir\appcompat\Programs\ $temp_path\files  >> $temp_path\files\Amcache.hve.txt -- does not work without rawcopy access, with other tools.
##robocopy $env:windir\System32\sru\ $temp_path\files >> $temp_path\files\sru.txt

## ramdump
Write-Host "starting ramcapture" -ForegroundColor Green
cd $work_path\RamCapturer64
$ramcapturer_path = "$work_path\RamCapturer64\RamCapture64.exe"
$ramcapturer_args = "$uuid.dump"
Function LoadingBar {For($I = 0; $I -le 100; $I = ($I + 1) % 100){Write-Progress -Activity "running Belkasoft ramcapture" -CurrentOperation "Please wait, dump will be copied to work dir and next steps will run automatically" -PercentComplete $I -Status "Dumping RAM";Start-Sleep -M 500;If ($LoadingProcess.HasExited) {Write-Progress -Activity "Dumping all RAM" -Completed;Sleep 1;Break}}}
$LoadingProcess = Start-Process -FilePath "$ramcapturer_path" -ArgumentList "$ramcapturer_args" -PassThru;LoadingBar;Sleep 1;$LoadingProcess.WaitForExit() | Out-Null



 
#3 - archive stuff
write-host "moving and packing" -ForegroundColor Green
Move-Item "$work_path\RamCapturer64\$uuid.dump" -Destination $temp_path\ramcapture
start-process "$work_path\7zip\7z.exe" -ArgumentList "$uuid.zip $temp_path\ -pSECRET"
C:\venor_v0rpal\7zip\7z.exe a C:\Users\User\AppData\Local\Temp\venor_v0rpal\forensics.zip C:\Users\User\AppData\Local\Temp\venor_v0rpal\forensics\ -pSECRET
C:\venor_v0rpal\7zip\7z.exe a -mx0 C:\Users\User\AppData\Local\Temp\venor_v0rpal\forensics.7z C:\Users\User\AppData\Local\Temp\venor_v0rpal\forensics\ -pSECRET

#4 - external tools
write-host "skipping more stuff" -ForegroundColor White
## C:\scripts\Get-AutorunsDeep.ps1 >> $temp_path\basic\autorunsc.txt
##C:\scripts\Get-PSProfiles.ps1 -- path handling seems broken....

#4 send stuff

### xxx

#x remove all
##rmdir -"$temp_path" -force -Recurse

#reset executionpolicy
write-host "doing miscstuff" -ForegroundColor Green
Set-executionpolicy -ExecutionPolicy $default_executionpolicy -Force