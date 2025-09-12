
## to clean usage of double special characters to adhere to csv standard, which does not work for re-import (e.g copy mde kql between tenants for example)
# Set the folder path containing the KQL files
$folderPath = "C:\Path\To\Your\KQLFiles"

# Get all .txt and .kql files in the folder
$files = Get-ChildItem -Path $folderPath -Filter *.txt, *.kql

foreach ($file in $files) {
    $filePath = $file.FullName
    $content = Get-Content $filePath -Raw

    # Replace double double-quotes with single double-quotes
    $cleanedContent = $content -replace '""', '"'

    # Optionally, save to a new file or overwrite the original
    $newFilePath = Join-Path $folderPath ("Cleaned_" + $file.Name)
    Set-Content -Path $newFilePath -Value $cleanedContent

    Write-Host "Cleaned: $filePath -> $newFilePath"
}
