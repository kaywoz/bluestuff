
<#
#Requires - selfcontained

.SYNOPSIS
    A script that performs some task.

.DESCRIPTION
    A detailed description of what the script does.

.PARAMETER InputFile
    The path to the input file.

.PARAMETER OutputFile
    The path to the output file.

.EXAMPLE
    .\\MyScript.ps1 -InputFile C:\\input.txt -OutputFile C:\\output.txt

    Runs the script with the specified input and output files.
#>


Write-Host -ForegroundColor darkblue "acompany"



##execution time

$scriptstartTime = Get-Date
$scriptendTime = Get-Date
$executionTime = $endTime - $startTime


##checks



# check if running as admin
write-host "checking admin" -ForegroundColor Green
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isadmintrue = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)


if ($isadmintrue -eq $False) {
    try {
        Start-Process PowerShell.exe -Verb runAs -ArgumentList C:\Users\User\Desktop\123.ps1
        } catch {
        Write-Output "Caught an exception: $_"
    }
} else {
    Write-Output "host seems to be admin, continuing..."


# check ps execution policy, interrogate and set as original when done.
write-host "fixing executionpolicy" -ForegroundColor Green
$default_executionpolicy = Get-ExecutionPolicy
Set-executionpolicy -ExecutionPolicy unrestricted -Force
Start-Sleep -Milliseconds 5000



##vars
write-host "setting vars" -ForegroundColor Green
$uuid = (Get-WmiObject -Class Win32_ComputerSystemProduct).UUID +"_"+(Get-Date -Format "yyyyMMddhhmm")
write-host "setting uuid" -ForegroundColor Yellow
$temp_path = "$env:TEMP\v0rpal\forensics\"
write-host "setting temp_path" -ForegroundColor Yellow
$work_path = "c:\v0rpal"
write-host "setting work_path" -ForegroundColor Yellow
$drop_path = "c:\v0rpal.zip"
write-host "setting drop_path" -ForegroundColor Yellow
$ErrorActionPreference = 'Stop' # sets the default error action preference to continue
write-host "setting ErrorActionPreference" -ForegroundColor Yellow
Start-Sleep -Milliseconds 5000

## misc checks for debugging
Remove-Item -Force $work_path -Recurse -ErrorAction SilentlyContinue #debug 
Remove-Item -Force c:\test\dir -Recurse -ErrorAction SilentlyContinue #debug
Remove-Item -force $temp_path -Recurse -ErrorAction SilentlyContinue #debug


#1.1 dir make
write-host "making dirs" -ForegroundColor Green

$success = $false
try {
mkdir "$temp_path" -InformationAction SilentlyContinue
mkdir "$temp_path\system" -InformationAction SilentlyContinue
mkdir "$temp_path\userinfo" -InformationAction SilentlyContinue
mkdir "$temp_path\networkinfo" -InformationAction SilentlyContinue
mkdir "$temp_path\fileprocessinfo" -InformationAction SilentlyContinue
mkdir "$temp_path\files" -InformationAction SilentlyContinue
mkdir "$temp_path\ramcapture" -InformationAction SilentlyContinue
$success = $true

Start-Sleep -Milliseconds 5000
} catch {
    Write-Output "Caught an exception: $_"
}

if ($success) {
   write-host "the following paths will be used;" -ForegroundColor Yellow
   gci $temp_path | Select-Object -ExpandProperty FullName | Format-Table | Out-String | Write-Host -ForegroundColor Yellow  
}


##1.2 manage external tools

$success = $false

try {
write-host "fixing tools" -ForegroundColor Green
Expand-Archive $drop_path -DestinationPath C:\ -ErrorAction SilentlyContinue # -Force
    $success = $true
} catch {
    Write-Output "Caught an exception: $_"
    Start-Sleep -Milliseconds 5000
    exit
}

if ($success) {
    Write-Output "extraction succeeded without errors."
    write-host "the following tool directories will be used;" -ForegroundColor Yellow
    gci $work_path | Select-Object -ExpandProperty FullName | Format-Table | Out-String | Write-Host -ForegroundColor Yellow  
    
}



#2 acquire

##2.1 system
write-host "starting system acquisition" -ForegroundColor Green

$success = $false

try {
systeminfo >> systeminfo.txt
schtasks /query /FO CSV /v | ConvertFrom-Csv >> $temp_path\system\scheduled_tasks.txt
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
    $success = $true
} catch {
    # Handle the error
    Write-Output "Caught an exception: $_"
}

if ($success) {
    # This block acts like the "else" part, running if no exception was caught
    Write-Output "system acquisition succeeded without errors."
}

Start-Sleep -Milliseconds 5000


##2.2 userinfo
write-host "starting userstuff" -ForegroundColor Green

$success = $false

try {
net user | Out-File $temp_path\userinfo\local_users.txt
net localgroup administrators | Out-File $temp_path\userinfo\local_admins.txt
    $success = $true
} catch {
    # Handle the error
    Write-Output "Caught an exception: $_"
}

if ($success) {
    # This block acts like the "else" part, running if no exception was caught
    Write-Output "user event acquisition succeeded without errors."
}

Start-Sleep -Milliseconds 5000

##2.3 network
$success = $false

try {
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
    $success = $true
} catch {
    # Handle the error
    Write-Output "Caught an exception: $_"
}

if ($success) {
    # This block acts like the "else" part, running if no exception was caught
    Write-Output "network acquisition succeeded without errors."
}



Start-Sleep -Milliseconds 5000

##2.4 fileprocessinfo
$success = $false

try {
write-host "starting fileprocessstuff" -ForegroundColor Green
Get-ChildItem -Attributes Hidden $HOME -Recurse -ErrorAction SilentlyContinue  | select Name, Length, LastAccessTime, LastWriteTime, Directory | ft -AutoSize | Out-File $temp_path\fileprocessinfo\hidden_files_directories.txt
tasklist /V | Out-File $temp_path\fileprocessinfo\processes.txt
tasklist /M | Out-File $temp_path\fileprocessinfo\dlls.txt
tasklist /SVC | Out-File  $temp_path\fileprocessinfo\service_processess.txt
    $success = $true
} catch {
    # Handle the error
    Write-Output "Caught an exception: $_"
}

if ($success) {
    # This block acts like the "else" part, running if no exception was caught
    Write-Output "files and process acquisition succeeded without errors."
}



Start-Sleep -Milliseconds 5000

##2.5 files
write-host "doing filesstuff" -ForegroundColor Yellow

$success = $false

try {

# Check for existing Volume Shadow Copies
$existingShadows = (vssadmin list shadows) -match "Shadow Copy Volume" | Select-Object -Last 1
if ($existingShadows.Length -gt 0) {
    Write-Host "Volume Shadow Copies exist, creating new one and and mounting..."
    
    $createShadowOutput = wmic shadowcopy call create volume="C:\" # refactor for variable? does not work
 

    $existingShadowsLatest = (vssadmin list shadows) -match "Shadow Copy Volume" | Select-Object -Last 1
    Write-Output "Existing Shadows Latest: $existingShadowsLatest"
    $fixedShadows = ($existingShadowsLatest -replace 'Shadow Copy Volume: ', '').Trim() + '\'

    Write-Host "Work path: $work_path"
    Write-Host "Using Fixed Shadows: $fixedShadows"
    
    Start-Process -FilePath "$env:comspec" -ArgumentList "/k", "mklink", "/j", "`"$work_path\\vsc`"","`"$fixedShadows`" & exit" -Verbose
    Write-Host "Fixed Shadows2: $fixedShadows" -Verbose
 


    # Assuming use of a third-party tool or manual process to mount
    # This example does not cover the complex process of mounting VSCs due to limitations in PowerShell and Windows API exposure
} else {
    Write-Host "No Volume Shadow Copies found. Creating one..."

    # Create a new Volume Shadow Copy
    # Note: This requires vssadmin and administrative privileges
    $createShadowOutput = wmic shadowcopy call create volume="C:\" # refactor for variable? does not work
    if ($createShadowOutput -match "successfully created") {
        Write-Host "Volume Shadow Copy created successfully, mounting..."

       

    $existingShadowsLatest = (vssadmin list shadows) -match "Shadow Copy Volume" | Select-Object -Last 1
    Write-Output "Existing Shadows Latest: $existingShadowsLatest"
    $fixedShadows = ($existingShadowsLatest -replace 'Shadow Copy Volume: ', '').Trim() + '\'

    Write-Host "Work path: $work_path"
    Write-Host "Using Fixed Shadows: $fixedShadows"
    
    Start-Process -FilePath "$env:comspec" -ArgumentList "/k", "mklink", "/j", "`"$work_path\\vsc`"","`"$fixedShadows`" & exit" -Verbose
    Write-Host "Fixed Shadows2: $fixedShadows" -Verbose
    } else {
    Write-Host "Failed to create Volume Shadow Copy."
    }
}

<#    # get existing shadow copies
$shadow = get-wmiobject win32_shadowcopy
"There are {0} shadow copies on this sytem" -f $shadow.count
""

# get static method
$class=[WMICLASS]"root\cimv2:win32_shadowcopy"

# create a new shadow copy
"Creating a new shadow copy"
$class.create("C:\", "ClientAccessible")

# Count again
$shadow = get-wmiobject win32_shadowcopy
"There are now {0} shadow copies on this sytem" -f $shadow.count
#>


#raw copy user related files, corresponds to sans blue poster, orlikoski cylr-list etc.



$filedestinationroot = Join-Path -Path $temp_path -ChildPath "files"

# Array of relative Windowspaths to copy
$relativeWindowsPaths = @(
    "Windows\Tasks\",
    "Windows\Prefetch\",
    "Windows\System32\sru\",
    "Windows\System32\winevt\Logs\",
    "Windows\System32\Tasks\",
    "Windows\System32\Logfiles\W3SVC1\",
    "Windows\Appcompat\Programs\",
    "Windows\SchedLgU.txt",
    "Windows\inf\setupapi.dev.log",
    "Windows\System32\drivers\etc\hosts",
    "Windows\System32\config\SAM",
    "Windows\System32\config\SOFTWARE",
    "Windows\System32\config\SECURITY",
    "Windows\System32\config\SYSTEM", # removed, impossible due to sensor protection, 
    # removed, impossible due to sensor protection, "Windows\System32\config\SAM.LOG1",
    "Windows\System32\config\SOFTWARE.LOG1",
    "Windows\System32\config\SECURITY.LOG1",
    "Windows\System32\config\SOFTWARE.LOG1",
    # removed, impossible due to sensor protection, "Windows\System32\config\SAM.LOG2",
    "Windows\System32\config\SOFTWARE.LOG2",
    "Windows\System32\config\SECURITY.LOG2", 
    "Windows\System32\config\SOFTWARE.LOG2"
)

# Loop through each path and execute xcopy
foreach ($relativeWindowsPath in $relativeWindowsPaths) {
    $source = Join-Path -Path $work_path -ChildPath "vsc\$relativeWindowsPath"
    $final_destination = Join-Path -Path $filedestinationroot -ChildPath $relativeWindowsPath*
    xcopy /H /Y /I $source $final_destination
}


# Array of relative ProgramDatapaths to copy
$relativeProgramDataPaths = @(
    "ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\"
)

# Loop through each path and execute xcopy
foreach ($relativeProgramDataPath in $relativeProgramDataPaths) {
    $source = Join-Path -Path $work_path -ChildPath "vsc\$relativeProgramDataPath"
    $final_destination = Join-Path -Path $filedestinationroot -ChildPath $relativeProgramDataPath*
    xcopy /H /Y /I $source $final_destination
}
$destination = Join-Path -Path $temp_path -ChildPath "files"
# Loop through each SystemDrivepath and execute xcopy
foreach ($SystemDrivepath in $SystemDrivepaths) {
    $source = Join-Path -Path $work_path -ChildPath "vsc\$relativeSystemDrivepaths"
    $final_destination = Join-Path -Path $filedestinationroot -ChildPath $relativeProgramDataPath*
    xcopy /H /Y /I $source $final_destination
}

<# Array of relative paths to copy
$relativeSystemDrivepaths = @(
    "$env:systemdrive\$Recycle.Bin\**\$I"
)#>

#manually copy items via index files from recycle bin container.
mkdir $filedestinationroot\recycle_bin # to be removed and placed earlier-> placeholder
$shell = New-Object -ComObject Shell.Application  
$recycleBin = $shell.Namespace(0xA) #Recycle Bin  
$recycleBin.Items() | %{Copy-Item $_.Path ("$filedestinationroot\recycle_bin\{0}" -f $_.Name)}
#$recycleBin.Items() | %{Copy-Item $_.Path ("C:\test\recycle_bin\{0}" -f $_.Name)}

#raw copy $MFT-file to dir
$rawcopy_args = "$work_path\RawCopy\RawCopy64.exe"
Start-Process -FilePath "$env:comspec" -ArgumentList "/c `"$rawcopy_args C:0 $temp_path\files\C`"" # -> refactor with other start-processes?

# Define the target root directory
$targetRootDir = "filedestinationroot\Users"

# Ensure the target root directory exists
if (-not (Test-Path -Path $targetRootDir)) {
    New-Item -Path $targetRootDir -ItemType Directory
}

# Define the paths to copy
$pathsToCopy = @(
    "NTUser.DAT",
    "NTUser.DAT.LOG1",
    "NTUser.DAT.LOG2",
    "AppData\Roaming\Microsoft\Windows\Recent",
    "AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt",
    "AppData\Roaming\Mozilla\Firefox\Profiles",
    "AppData\Local\Microsoft\Windows\WebCache",
    "AppData\Local\Microsoft\Windows\Explorer",
    "AppData\Local\Microsoft\Windows\UsrClass.dat",
    "AppData\Local\Microsoft\Windows\UsrClass.dat.LOG1",
    "AppData\Local\Microsoft\Windows\UsrClass.dat.LOG2",
    "AppData\Local\Microsoft\Terminal Server Client\Cache",
    "AppData\Local\ConnectedDevicesPlatform",
    "AppData\Local\Google\Chrome\User Data\Default\History",
    "AppData\Local\Microsoft\Edge\User Data\Default\History",
    "AppData\Local\Google\Chrome\User Data",
    "AppData\Local\Microsoft\Edge\User Data",
    "AppData\Local\Mozilla\Firefox\Profiles",
    "AppData\Local\Microsoft\Windows\Temporary Internet Files",
    "AppData\Local\Microsoft\Windows\INetCache",
    "AppData\Local\Microsoft\Windows\WebCache",
    "AppData\Local\BraveSoftware\Brave-Browser\User Data"


) ### -> some kind of pathing error for cache directories.

# Get all user profiles
$userProfiles = Get-ChildItem -Path $work_path\vsc\Users -Directory

foreach ($user in $userProfiles) {
    # Create a specific target directory for each user
    $userTargetDir = Join-Path -Path $targetRootDir -ChildPath $user.Name
    # Ensure the user's target directory exists
    if (-not (Test-Path -Path $userTargetDir)) {
        New-Item -Path $userTargetDir -ItemType Directory
    }
    
    foreach ($relativePath in $pathsToCopy) {
        $sourcePath = Join-Path -Path $user.FullName -ChildPath $relativePath
        # Adjust $destPath to include the user's folder at the target location
        $destPath = Join-Path -Path $userTargetDir -ChildPath $relativePath

        if (Test-Path -Path $sourcePath) {
            # Ensure the destination directory exists
            $destDir = [System.IO.Path]::GetDirectoryName($destPath)
            if (-not (Test-Path -Path $destDir)) {
                New-Item -Path $destDir -ItemType Directory -Force
            }

            # Determine if the source is a file or directory
            if (Test-Path -Path $sourcePath -PathType Leaf) {
                # Source is a file, construct arguments for xcopy
                $xcopyArgs = @($sourcePath, $destDir, "/H", "/Y", "/I")
            } else {
                # Source is a directory, include /E to copy all subdirectories (including empty ones)
                $xcopyArgs = @("$sourcePath\*", "$destPath\", "/E", "/H", "/Y", "/I")
            }

            # Execute xcopy command
            Start-Process "xcopy" -ArgumentList $xcopyArgs -NoNewWindow -Wait
        }
    }
}

# Define the base variables
$userProfiles = Get-ChildItem -Path $work_path\vsc\Users -Directory

# Define an array of file filters
$fileFilters = @('*.ps1') #('*.exe', '*.dll', '*.js','*,vbs','*.ps1')

# Prepare an array to hold the results
$results = @()

foreach ($user in $userProfiles) {
    foreach ($filter in $fileFilters) {
        # Use -ErrorAction SilentlyContinue to skip errors like access denied
        $files = Get-ChildItem -Path $user.FullName -Recurse -Filter $filter -File -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            # Calculate MD5 and SHA256 hashes for each file
            $md5Hash = (Get-FileHash -Path $file.FullName -Algorithm MD5).Hash
            $sha256Hash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash

            # Create a custom object with the details and add it to the results array
            $result = [PSCustomObject]@{
                Name          = $file.Name
                ProductName    = $file.VersionInfo.ProductName
                DirectoryName = $file.DirectoryName
                LastWriteTime  = $file.LastWriteTime
                LastAccessTime = $file.LastAccessTime
                MD5Hash       = $md5Hash
                SHA256Hash    = $sha256Hash
            }
            $results += $result
        }
    }
}

# Export the results to a CSV file for full visibility
#$results | Export-Csv -Path "C:\path\to\output.csv" -NoTypeInformation

# For immediate console output, adjust or remove columns as necessary to fit
 $results | Export-Csv -Path $filedestinationroot\fileinfo.csv
 $fileFiltersCount = ($results | Measure-Object).count
 Write-host "$fileFiltersCount files were hashed and inventoried... continuing..." -ForegroundColor yellow

write-host "check the ioa exclusions when needed" # https://falcon.eu-1.crowdstrike.com/configuration/exclusions/ioa/details/49bb51729b124848a9dc4aba67254a88

<#  
    #>
    $success = $true
} catch {
    # Handle the error
    Write-Output "Caught an exception: $_"
}

if ($success) {
    # This block acts like the "else" part, running if no exception was caught
    Write-Output "files acquisition succeeded without errors."
}
##robocopy -zb $env:windir\appcompat\Programs\ $temp_path\files  >> $temp_path\files\Amcache.hve.txt
##robocopy $env:windir\System32\sru\ $temp_path\files >> $temp_path\files\sru.txt
Start-Sleep -Milliseconds 5000

##2.6 ramdump
Write-Host "starting ramcapture" -ForegroundColor Green

$success = $false

try {

cd $work_path\RamCapturer64
$ramcapturer_path = "$work_path\RamCapturer64\RamCapture64.exe"
$ramcapturer_args = "$uuid.dump"
Function LoadingBar {For($I = 0; $I -le 100; $I = ($I + 1) % 100){Write-Progress -Activity "running Belkasoft ramcapture" -CurrentOperation "dump will be copied to work dir and next steps will run automatically" -PercentComplete $I -Status "Dumping RAM";Start-Sleep -M 500;If ($LoadingProcess.HasExited) {Write-Progress -Activity "Dumping all RAM" -Completed;Sleep 1;Break}}}
$LoadingProcess = Start-Process -FilePath "$ramcapturer_path" -ArgumentList "$ramcapturer_args" -PassThru;LoadingBar;Sleep 1;$LoadingProcess.WaitForExit() | Out-Null

    $success = $true
} catch {
    # Handle the error
    Write-Output "Caught an exception: $_"
}

if ($success) {
    # This block acts like the "else" part, running if no exception was caught
    Write-Output "ramcapture succeeded without errors."
}

 
#3.1 archive stuff
write-host "moving and packing" -ForegroundColor Green
Move-Item "$work_path\RamCapturer64\$uuid.dump" -Destination $temp_path\ramcapture
start-process "$work_path\7zip\7z.exe" -ArgumentList "$uuid.zip $temp_path\ -pSECRET"
C:\v0rpal\7zip\7z.exe a -mx0 C:\Users\User\AppData\Local\Temp\v0rpal\forensics.7z C:\Users\User\AppData\Local\Temp\v0rpal\forensics\* -pNurhVgtQHg9r9rFobqQfLT4xUxv8ZRQLwDkeTiMmGaqXKvDZ3dn
Start-Job -ScriptBlock {invoke-webrequest -method put -infile C:\Users\User\AppData\Local\Temp\v0rpal\forensics.7z https://transfer.sh/testfile}
Start-Sleep -Milliseconds 5000

#4.1 - external tools
write-host "skipping more stuff" -ForegroundColor White
Start-Sleep -Milliseconds 5000
## C:\scripts\Get-AutorunsDeep.ps1 >> $temp_path\basic\autorunsc.txt
##C:\scripts\Get-PSProfiles.ps1 -- path handling seems broken....

#4 send stuff

### xxx

#x remove all
##rmdir -"$temp_path" -force -Recurse

#reset executionpolicy
write-host "doing miscstuff" -ForegroundColor Green -Verbose
Set-executionpolicy -ExecutionPolicy $default_executionpolicy -Force -Verbose
Start-Sleep -Milliseconds 5000

}

$scriptendTime = Get-Date
$executionTime = $endTime - $startTime
Write-Host "Script execution time: $executionTime"
Write-Host "ALL DONE" -ForegroundColor Green  


<#
to add;
fileinfo from interesting places,
tasks,
services
networkshares
common registrykeys
prefetch
shadowcopies
downloads
eventlogs



#Upload file to Google Cloud Storage
$dir = "C:\PATH\TO\OBJECT\image.jpg"
$bucket_name = "[BUCKET_NAME]"
$Uri = "https://www.googleapis.com/upload/storage/v1/b/$bucket_name/o?uploadType=media&name=image.jpg"

Invoke-RestMethod -Method Post -Uri $Uri -Header $header -ContentType "image/jpg" -InFile "$dir"

#Download from Google Cloud Storage
$bucket_name = "[BUCKET_NAME]"
$bucket_file = "https://storage.googleapis.com/$bucket_name/image.jpg"
Invoke-RestMethod -Uri "$bucket_file" -Method Get -OutFile C:image.jpg

*error handling

#>
