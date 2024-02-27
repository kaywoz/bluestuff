##2.5 files
write-host "doing filesstuff" -ForegroundColor Yellow

$success = $false

# Check for existing Volume Shadow Copies
$existingShadows = (vssadmin list shadows) -match "Shadow Copy Volume" | Select-Object -Last 1
if ($existingShadows.Length -gt 0) {
    Write-Host "Volume Shadow Copies exist, creating new one and and mounting..."
    $volume = (Get-WmiObject -Class Win32_Volume -Filter "DriveType = 3") | Select-Object -Index 1 | Select-Object Name
    $createShadowOutput = wmic shadowcopy call create volume=$volume
    $fixedShadows = ($existingShadows -replace 'Shadow Copy Volume: ', '').Trim() + '\'
    Write-Output $fixedShadows
    Start-Process -FilePath "$env:comspec" -ArgumentList "/k", "mklink", "/j", "`"C:\$work_path\mklink`"","`"$fixedShadows`" & exit"
    # Assuming use of a third-party tool or manual process to mount
    # This example does not cover the complex process of mounting VSCs due to limitations in PowerShell and Windows API exposure
} else {
    Write-Host "No Volume Shadow Copies found. Creating one..."

    # Create a new Volume Shadow Copy
    # Note: This requires vssadmin and administrative privileges
    $volume = (Get-WmiObject -Class Win32_Volume -Filter "DriveType = 3") | Select-Object -Index 1 | Select-Object Name
    $createShadowOutput = wmic shadowcopy call create volume=$volume
    if ($createShadowOutput -match "successfully created") {
        Write-Host "Volume Shadow Copy created successfully, mounting..."

        $existingShadows = (vssadmin list shadows) -match "Shadow Copy Volume" | Select-Object -Last 1
        $fixedShadows = ($existingShadows -replace 'Shadow Copy Volume: ', '').Trim() + '\'
        Write-Output $fixedShadows
        Start-Process -FilePath "$env:comspec" -ArgumentList "/k", "mklink", "/j", "`"C:\$work_path\mklink`"","`"$fixedShadows`" & exit"
    } else {
    Write-Host "Failed to create Volume Shadow Copy."
    }
}

try {

$rawcopy_args = "$env:windir\appcompat\Programs\ $temp_path\files\amcache"
Start-Process $rawcopy_path -ArgumentList $rawcopy_args # >> $temp_path\system\autorunsc.txt
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