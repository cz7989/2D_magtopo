#!/bin/sh

#事先已经phonopy处理完毕，保证和db中的sg一致
#该脚本位于magdir平行目录中
#还需要 usefindsym.csh, strong_corr
#原胞标准化+判断磁空间群+magset文件

posdir=poscar_square_phonopy
out_mag=magset_store_square
rm -rf linshidir $out_mag phonopy_result findsym_result
mkdir linshidir $out_mag
cp usefindsym.csh linshidir
ls $posdir > allposname
nstr=`awk 'END{print NR}' allposname`
for ((istr=1;istr<=nstr;istr++))
do
	zpos=`sed -n "$istr"p allposname`
	zstrname=${zpos#*_}
	cp "$posdir"/"$zpos" linshidir/PPOSCAR
	cd linshidir
	rm -f magset
	phonopy_sg=`awk -v zstrname=$zstrname '$2==zstrname{print $4;exit}' ../db_sgnumber`
	echo \!useKeyWords > fsdata
	echo \!latticeBasisVectors >> fsdata
	sed -n 3,5p PPOSCAR >> fsdata
	echo \!atomCount >> fsdata
	elename=(`sed -n 6p PPOSCAR`)
	natomlist=(`sed -n 7p PPOSCAR`)
	neletype=${#elename[*]}
	atomcount=0
	for zint in ${natomlist[*]}; do atomcount=$[atomcount+zint]; done
	echo $atomcount >> fsdata
	echo \!atomType >> fsdata
	for ((iele=1;iele<=neletype;iele++)); do zelement=${elename[iele-1]}; znatom=${natomlist[iele-1]}; awk -v a=$znatom -v b=$zelement 'BEGIN{printf a"*"b" "}'; done >> fsdata
	echo >> fsdata
	echo \!atomPosition >> fsdata
	awk 'NR>8{print $0}' PPOSCAR >> fsdata
	echo \!atomMagneticMoment >> fsdata
#mag in fsdata and magsetfile
	rm -f MAGMOMfile
	for ((iele=1;iele<=neletype;iele++))
	do
		zelement=${elename[iele-1]}
		check_corr=`awk -v zele=$zelement 'BEGIN{checkresult=0}{if($1==zele){checkresult=1;exit}}END{print checkresult}' ../strong_corr`
		znatom=${natomlist[iele-1]}
		if [ $check_corr -eq 1 ]; then  #关联元素原子加磁，z方向，大小为3muB
			awk -v znatom=$znatom 'BEGIN{for(i=1;i<=znatom;i++){print "0 0 3"}}' >> fsdata
			awk -v znatom=$znatom 'BEGIN{for(i=1;i<=znatom;i++){printf "0 0 3 "}}' >> MAGMOMfile
		else
			awk -v znatom=$znatom 'BEGIN{for(i=1;i<=znatom;i++){print "0 0 0"}}' >> fsdata
			awk -v znatom=$znatom 'BEGIN{printf 3*znatom"*0 "}' >> MAGMOMfile
		fi
	done
#get magnetic space group from FINDSYM
	./usefindsym.csh > findsym_info
	fs_msg=`grep "Magnetic Space Group:" findsym_info | awk '{print $4}'`
	fs_sg=${fs_msg%.*}
	fs_bns=${fs_msg#*.}
	kptsifile=~/soft/Mvasp2trace/MagneticKvecs/MagneticKvecs_"$fs_sg"_"$fs_bns".txt
	if [ $fs_sg -eq $phonopy_sg ]; then
		sed -i "1c MSG: $fs_sg $fs_bns" PPOSCAR
		echo POSCAR_msg: > magset
		cat PPOSCAR >> magset
		echo >> magset
		echo INCAR: >> magset
		echo "LSORBIT = T" >> magset
		awk 'BEGIN{printf "MAGMOM="}{print $0}' MAGMOMfile >> magset
		echo >> magset
		echo KPOINTS: >> magset
		echo MKPOINTS >> magset
		nk=`awk 'END{print NR}' $kptsifile`
		echo $nk >> magset
		echo rec >> magset
		awk '{print $1" "$2" "$3" 1.0 ! "$4}' $kptsifile >> magset
		echo >> magset
		#output PPOSCAR, magset
		mv -f magset ../"$out_mag"/magset_"$zstrname"
		echo "结构转换成功："$zstrname"  "$fs_sg"  "$phonopy_sg >> ../findsym_result
	else
		echo "结构转换有误："$zstrname"  "$fs_sg"  "$phonopy_sg >> ../findsym_result
	fi
	cd ../

        if [ `awk -v i=$istr 'BEGIN{print i%100}'` -eq 0 ]; then
                echo "已完成结构："$istr
        fi
done


