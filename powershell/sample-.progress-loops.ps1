$outer=@(1..10)
$inner=@(1..100)

$counter=1
foreach($x in $outer){
	$innercounter=1
	foreach($y in $inner){
	write-progress -id 2 -activity "Task progress" -status "$(($innercounter/$inner.Count)*100)% Complete" -Percentcomplete $(($innercounter/$inner.Count)*100)
	$innercounter++
	start-sleep -milliseconds 100
	}
	write-progress -id 1 -activity "Job progress" -status "$(($counter/$outer.Count)*100)% Complete" -Percentcomplete $(($counter/$outer.Count)*100)
	$counter++
	start-sleep -milliseconds 100
}ll