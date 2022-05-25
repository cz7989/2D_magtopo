#!/bin/sh

posdir=poscar_square
posdir_out="$posdir"_phonopy
rm -rf $posdir_out
mkdir $posdir_out
rm -rf checksg_diff checksg_result
ls $posdir > allposname
sed -i 's/_/ /g' allposname
nstr=`awk 'END{print NR}' allposname`
for ((istr=1;istr<=nstr;istr++))
do
	zstrname=`sed -n "$istr"p allposname | awk '{print $2}'`
	zsg_db=`awk -v zstrname=$zstrname '$2==zstrname{print $4;exit}' db_sgnumber`
	zpos=$posdir/POSCAR_$zstrname
	rm -f phonopy_info PPOSCAR
	phonopy --symmetry --tolerance 0.1 -c $zpos > phonopy_info
	zsg_phonopy=`grep "space_group_number:" phonopy_info | awk '{print $2}'`
	echo $zstrname $zsg_db $zsg_phonopy >> checksg_result
	if [ $zsg_db -ne $zsg_phonopy ]; then
		echo $zstrname $zsg_db $zsg_phonopy >> checksg_diff
	else
		mv -f PPOSCAR $posdir_out/POSCAR_$zstrname
	fi
        if [ `awk -v i=$istr 'BEGIN{print i%100}'` -eq 0 ]; then
                echo "已完成结构："$istr
        fi
done
