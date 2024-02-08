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
Set-executionpolicy -ExecutionPolicy $default_executionpolicy -Force

##vars
write-host "setting vars" -ForegroundColor Green
$temp_path = "$env:TEMP\Venor\forensics\"
$uuid = (Get-WmiObject -Class Win32_ComputerSystemProduct).UUID +"_"+(Get-Date -Format "yyyyMMddhhmm")
$work_path = "c:\venor_v0rpal"
$drop_path = "c:\venor_v0rpal.zip"

#1 dir make
write-host "making dirs" -ForegroundColor Green
rmdir "$temp_path" -force -Recurse
mkdir "$temp_path\system"
mkdir "$temp_path\userinfo"
mkdir "$temp_path\networkinfo"
mkdir "$temp_path\fileprocessinfo"
mkdir "$temp_path\files"
mkdir "$temp_path\ramcapture"

## manage external tools
write-host "fixing tools" -ForegroundColor Green
Expand-Archive $drop_path

#2 acquire

## system
write-host "starting system acquisition"
systeminfo >> systeminfo.txt
$tool_path\lastactivityview\LastActivityView.exe /stab $temp_path\system\lastactivityview.csv
ForEach ($NameSpace in "root\subscription","root\default") { get-wmiobject -namespace $NameSpace -query "select * from __EventConsumer" >> $temp_path\system\wmi.txt } 
wmic product list >> wmic_software.txt
wmic sysdriver list full >> wmic_system_drivers.txt
wmic list full >> wmic_logon_list.txt
wmic loadorder list full >> wmic_loadorder.txt
wmic.exe diskdrive list brief /format:list >> wmic_diskdrive.txt
$tool_path\SysinternalsSuite\autorunsc64.exe -accepteula >> autorunsc64.txt

##userinfo
write-host "starting userstuff" -ForegroundColor Green
net user >> $temp_path\userinfo\local_users.txt
net localgroup administrators >> $temp_path\userinfo\local_admins.txt 

##network
write-host "starting networkstuff" -ForegroundColor Green
nbtstat.exe -c >> $temp_path\networkinfo\nbtstat.txt
nbtstat.exe -S >> $temp_path\networkinfo\nbtstat.txt
netstat.exe -anb >> $temp_path\networkinfo\netstat_anb_results.txt
ipconfig /all >> $temp_path\networkinfo\ipsettings.txt
ipconfig /displaydns >> $temp_path\networkinfo\dns_cache.txt
netstat -anob >> $temp_path\networkinfo\open_network_connections.txt
netstat -rn >> $temp_path\networkinfo\routing_tables.txt
arp -a >> $temp_path\networkinfo\arp.txt
$tool_path\SysinternalsSuite\Tcpvcon.exe –a >> $temp_path\networkinfo\tcpconv.txt
net sessions >> $temp_path\networkinfo\netbios_sessions.txt

##fileprocessinfo
write-host "starting fileprocessstuff" -ForegroundColor Green
Get-ChildItem -Attributes Hidden $HOME -Recurse -ErrorAction SilentlyContinue >> $temp_path\fileprocessinfo\hidden_files_directories.txt
tasklist /V >> $temp_path\fileprocessinfo\processes.txt
tasklist /M >> $temp_path\fileprocessinfo\dlls.txt
tasklist /SVC >>  $temp_path\fileprocessinfo\service_processess.txt

##files
write-host "skipping filesstuff for now" -ForegroundColor Yellow
##robocopy -zb $env:windir\appcompat\Programs\ $temp_path\files  >> $temp_path\files\Amcache.hve.txt -- does not work without rawcopy access, with other tools.
##robocopy $env:windir\System32\sru\ $temp_path\files >> $temp_path\files\sru.txt

## ramdump
Write-Host "starting ramcapture" -ForegroundColor Green
$tool_path\RamCapturer\RamCapture64.exe $uuid
Copy-Item "$tool_path\RamCapturer\$uuid.dump" -DestinationPath $temp_path\ramcapture

#3 - archive stuff
write-host "moving and packing" -ForegroundColor Green
Compress-Archive -Path $temp_path -DestinationPath $temp_path\$uuid.zip

#4 - external tools
write-host "skipping more stuff" -ForegroundColor White
## C:\scripts\Get-AutorunsDeep.ps1 >> $temp_path\basic\autorunsc.txt
##C:\scripts\Get-PSProfiles.ps1 -- path handling seems broken....

#4 send stuff

### xxx

#x remove all
##rmdir -"$temp_path" -force -Recurse

#x remove all
##rmdir -"$temp_path" -force -Recurse

#reset executionpolicy
write-host "doing miscstuf" -ForegroundColor Green
Set-executionpolicy -ExecutionPolicy $default_executionpolicy -Force