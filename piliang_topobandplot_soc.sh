#!/bin/sh

tarname=topoband_honeycomb_fm001.tar
rm -rf band_col
mkdir band_col
rm -f bandplot_record


npic=`awk 'END{print NR}' scfcheck_result_honeycomb`
for ((ipic=1;ipic<=npic;ipic++))
do
	zpicxx=(`sed -n "$ipic"p scfcheck_result_honeycomb`)
	zstrname=${zpicxx[0]}
	zucalname=${zpicxx[1]}
	zchem=`awk 'NR==1{for(i=1;i<=NF;i++){printf $i};exit}' poscar_fromdb/POSCAR_$zstrname`
	cd honeycomb_cal/$zstrname/fm_001/$zucalname
        cd bands_result
	if [ ! -f ../dos_result/DOSCAR ]; then
		echo "错误：dos计算失败  "$zstrname $zucalname
		exit
	fi
	cp ../dos_result/DOSCAR ./  #读取费米能
	rm -f *.jpg
	echo -e "21\n211" | vaspkit
	#bulkband plot
	zpicname="$zstrname"_"$zchem"_"$zucalname"
	zpbandfile=REFORMATTED_BAND.dat
	xmax=`awk 'END{print $1}' $zpbandfile`
	ymin=-2
	ymax=2
	nband=`awk 'NR==2{print NF-1;exit}' $zpbandfile`
	nele=`awk '{if(NR==6){print $1;exit}}' EIGENVAL`
	nocc=$nele  #soc
	#write gnufile
	echo set terminal jpeg enhanced font \"/fs04/home/xgw_caozp/arial.ttf,40\" size 1920,1680 > band.gnu
	echo set key outside >> band.gnu
	echo set noxtics >> band.gnu
	echo set xrange [0:$xmax] >> band.gnu
	echo set yrange [$ymin:$ymax] >> band.gnu
	echo set output \"$zpicname.jpg\" >> band.gnu
	echo set title \"$zpicname\" >> band.gnu
	ylabelwz=`awk -v ymin=$ymin 'BEGIN{print ymin-0.1}'`
	klabel=(`awk 'NR>=2{if(NF==2){printf $1" "}else{exit}}' KLABELS`)
	kwz=(`awk 'NR>=2{if(NF==2){printf $2" "}else{exit}}' KLABELS`)
	for ((isymk=1;isymk<=${#klabel[*]};isymk++))
	do
        	echo set label \"${klabel[isymk-1]}\" at ${kwz[isymk-1]}, $ylabelwz , 0 centre norotate >> band.gnu
	        echo set arrow from ${kwz[isymk-1]}, $ymin to ${kwz[isymk-1]}, $ymax nohead >> band.gnu
	done
	echo set arrow from 0, 0 to $xmax, 0 nohead lw 2 lc 3 dashtype \'-\' >> band.gnu
	echo plot \\ >> band.gnu
        for ((ib=1;ib<=nband;ib++))
        do
                if [ $ib -eq $nocc ]; then
                        echo \"$zpbandfile\" u 1:$[ib+1] w lines lt 7 lw 4 lc rgb \"red\" t \"\" >> band.gnu
                else
                        echo \"$zpbandfile\" u 1:$[ib+1] w lines lt -1 lw 4 lc rgb \"blue\" t \"\" >> band.gnu
                fi
                if [ $ib -ne $nband ]; then
                        sed -i '$ s/$/ , \\/' band.gnu
                fi
        done
	gnuplot band.gnu
	mv -f *.jpg /fs04/home/xgw_caozp/2Dmatpedia_vasp/band_col/
	cd /fs04/home/xgw_caozp/2Dmatpedia_vasp/
done
rm -rf $tarname
tar -cf $tarname band_col

