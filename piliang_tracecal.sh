#!/bin/sh

tarname=trace_honeycomb_fm001.tar
rm -rf trace_col
mkdir trace_col


npic=`awk 'END{print NR}' scfcheck_result_honeycomb`
for ((ipic=1;ipic<=npic;ipic++))
do
	zpicxx=(`sed -n "$ipic"p scfcheck_result_honeycomb`)
	zstrname=${zpicxx[0]}
	zucalname=${zpicxx[1]}
	zchem=`awk 'NR==1{for(i=1;i<=NF;i++){printf $i};exit}' poscar_fromdb/POSCAR_$zstrname`
	cd honeycomb_cal/$zstrname/fm_001/$zucalname
        cd si_result
	nelectron=`awk '{if(NR==6){print $1;exit}}' EIGENVAL`
	msgxx=(`sed -n 1p POSCAR`)
	msgroup="${msgxx[1]}"_"${msgxx[2]}"
	cp ~/soft/Mvasp2trace/Magnetic_Sym_El/Magnetic_Sym_El_"$msgroup".txt msg.txt
	Mvasp2trace $nelectron
	mv -f trace.txt /fs04/home/xgw_caozp/2Dmatpedia_vasp/trace_col/"$zstrname"_"$zchem"_"$zucalname".txt
	cd /fs04/home/xgw_caozp/2Dmatpedia_vasp/

        if [ `awk -v i=$ipic 'BEGIN{print i%50}'` -eq 0 ]; then
                echo "已完成结构："$ipic
        fi
done
rm -rf $tarname
tar -cf $tarname trace_col

