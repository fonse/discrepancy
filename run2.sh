#!/bin/bash

orders=`seq 20`
seqs="champer ford em"
generate=true


T="$(date +%s)"
dir=`dirname $0`
if [ ! -e $dir/data/2 ]; then mkdir -p $dir/data/2; fi
if [ ! -e $dir/graphs/2 ]; then mkdir -p $dir/graphs/2; fi

if [ ! -e $dir/bin/extford2 ]; then g++ $dir/lib/extford2.cpp -o $dir/bin/extford2; fi
if [ ! -e $dir/bin/ocurrencias ]; then  g++ $dir/lib/ocurrencias.cpp -o $dir/bin/ocurrencias; fi

if [ $generate ]
then
	echo "Generating sequences..."
	$dir/bin/champer2.py 1000000 > $dir/data/2/champer.txt
	$dir/bin/extford2 1000000 > $dir/data/2/ford.txt
	cp $dir/extra/em.txt $dir/data/2/em.txt
fi

for seq in $seqs
do
	if [ ! -e "$dir/graphs/2/$seq" ]; then mkdir "$dir/graphs/2/$seq"; fi

	echo -n "Processing $seq..."
	for i in $orders
	do
		echo -n " $i"
		if [ $generate ]
		then
			$dir/bin/ocurrencias 2 "$dir/data/2/$seq.txt" 1000000 $i > "$dir/data/2/$seq-$i.raw"
			$dir/bin/extract_disc.py "$dir/data/2/$seq-$i.raw" 2 $i > "$dir/data/2/$seq-$i.dat"
			$dir/bin/extract_peak.py "$dir/data/2/$seq-$i.raw" 2 $i > "$dir/data/2/$seq-$i-peaks.dat"
		fi
		
		gnuplot 2>/dev/null <<- EOF
			set terminal png

			set grid
			set logscale x
			set xtics ("2" 2, "2²" 4, "2³" 8, "2⁴" 16, "2⁵" 32, "2⁶" 64, "2⁷" 128, "2⁸" 256, "2⁹" 512, "2¹⁰" 1024, "2¹¹" 2048, \
			           "2¹²" 4096, "2¹³" 8192, "2¹⁴" 16384, "2¹⁵" 32768, "2¹⁶" 65536, "2¹⁷" 131072, "2¹⁸" 262144, "2¹⁹" 524288)

			a1 = b1 = c1 = 1
			a2 = b2 = c2 = 0.0001
			cotaS(n) = a1 * log(n)/n + a2
			cotaM(n) = b1 * sqrt(log(n)/n) + b2
			cotaL(n) = n<2?0: c1 * log(log(n)/log(2)) / (log(n)) + c2

			fit cotaS(x) '$dir/data/2/$seq-$i-peaks.dat' via a1, a2
			fit cotaM(x) '$dir/data/2/$seq-$i-peaks.dat' via b1, b2
			fit cotaL(x) '$dir/data/2/$seq-$i-peaks.dat' via c1, c2
			
			set output "$dir/graphs/2/$seq/$seq-$i.png"
			plot '$dir/data/2/$seq-$i.dat' title 'Discrepancia' with lines, \
			     '$dir/data/2/$seq-$i-peaks.dat' title 'Peaks' with points pointtype 7, \
			     cotaS(x) title 'Cota S' with lines, \
			     cotaM(x) title 'Cota M' with lines, \
			     cotaL(x) title 'Cota L' with lines
		EOF
	done
	
	echo ""
done

T="$(($(date +%s)-T))"
printf "\nTime taken: %02dm %02ds\n" "$((T/60%60))" "$((T%60))"
echo "Total disk usage: `du -ch data2/ | tail -n 1 | cut -f1`"