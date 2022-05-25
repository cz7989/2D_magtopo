#!/bin/sh

rm -f scfcheck_result bandcheck_result doscheck_result sicheck_result

magdir=magset_store_honeycomb
caldir=honeycomb_cal
ls $magdir > allmagname
nstr=`awk 'END{print NR}' allmagname`
for ((istr=1;istr<=nstr;istr++))
do
        zmag=`sed -n "$istr"p allmagname`
        zstrname=${zmag#*_}
        cd $caldir
        cd $zstrname
	strcaldir=fm_001
	ulist=(0 2 4 6 8)
	nucal=${#ulist[*]}
	cd $strcaldir
	for ((iucal=1;iucal<=nucal;iucal++))
	do
        	zu=${ulist[iucal-1]}
	        zucalname="u"$zu
	        cd $zucalname
		ls output_* >lsfile
	        outfile=`awk 'END{print $1}' lsfile`
	        maglist=(`awk '{if($1==1){printf $10" "$11" "$12;exit}}' $outfile`)
	        cd scf_result
	        grep "Iteration" OUTCAR >lsfile
	        niter=`awk 'END{print $4}' lsfile`
	        niter=${niter%)*}
		echo "$zstrname" "$zucalname"  \|  `grep "Total CPU time used" OUTCAR`  \|  "niter: "$niter  \|  "mag: "${maglist[*]} >> /fs04/home/xgw_caozp/2Dmatpedia_vasp/scfcheck_result
	        cd ../
	        cd bands_result
	        echo "$zstrname" "$zucalname" `grep "Total CPU time used" OUTCAR` >> /fs04/home/xgw_caozp/2Dmatpedia_vasp/bandcheck_result
	        cd ../
		cd dos_result
		echo "$zstrname" "$zucalname" `grep "Total CPU time used" OUTCAR` >> /fs04/home/xgw_caozp/2Dmatpedia_vasp/doscheck_result
		cd ../
	        cd si_result
	        echo "$zstrname" "$zucalname" `grep "Total CPU time used" OUTCAR` >> /fs04/home/xgw_caozp/2Dmatpedia_vasp/sicheck_result
	        cd ../

	        cd ../  #zucalname
	done
	cd ../  #strcaldir
	cd ../  #zstrname
	cd ../  #caldir
done

