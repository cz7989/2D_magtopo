#!/bin/sh

#批量计算magset_store中所有结构
#每个结构一个磁构型，几个U值

magdir=magset_store_square
caldir=square_cal
mkdir $caldir
ls $magdir > allmagname
nstr=`awk 'END{print NR}' allmagname`
for ((istr=1;istr<=nstr;istr++))
do
        zmag=`sed -n "$istr"p allmagname`
        zstrname=${zmag#*_}
	cd $caldir
	mkdir $zstrname
	cd $zstrname
	cp ../../"$magdir"/"$zmag" magset
	cp ../../vaspjob.sh ./
	cp ../../strong_corr ./

#uhtcal 开始
#当前位于某一结构计算的目录中
ncore=32
strcaldir=fm_001
ulist=(0 2 4 6 8)
nucal=${#ulist[*]}
rm -rf zcalinput
mkdir zcalinput
magfile=magset
awk 'BEGIN{hs=9999}{if($1=="POSCAR_msg:"){hs=NR}if(NR>hs){print $0;if($1==""){exit}}}' $magfile >zcalinput/POSCAR
awk 'BEGIN{hs=9999}{if($1=="INCAR:"){hs=NR}if(NR>hs){print $0;if($1==""){exit}}}' $magfile >zcalinput/INCAR_ncl
awk 'BEGIN{hs=9999}{if($1=="KPOINTS:"){hs=NR}if(NR>hs){print $0;if($1==""){exit}}}' $magfile >zcalinput/KPOINTSsi
cd zcalinput
#POTCAR
echo -e "1\n103" | vaspkit >lsfile
tve=`grep "Total Valence Electrons:" lsfile | awk '{printf("%d",$4)}'`
ndiv=`awk -v tve=$tve -v ncore=$ncore 'BEGIN{printf("%d",2*tve/ncore)}'`
ndiv=$[ndiv+1]
nbands=$[ndiv*ncore]
#KPOINTSbands
nkline=30
nkpt=`sed -n 2p KPOINTSsi`
echo K-Path > KPOINTSbands
echo $nkline >> KPOINTSbands
echo Line-Mode >> KPOINTSbands
echo Reciprocal >> KPOINTSbands
for ((i=1;i<=nkpt-1;i++))
do
	zstart=$[3+i]
	zend=$[3+i+1]
	awk -v a=$zstart 'NR==a{print $1" "$2" "$3"    "$6;exit}' KPOINTSsi >> KPOINTSbands
	awk -v a=$zend 'NR==a{print $1" "$2" "$3"    "$6;exit}' KPOINTSsi >> KPOINTSbands
	echo " " >> KPOINTSbands
done
#KPOINTSself, 0.02
echo -e "1\n102\n2\n0.02" | vaspkit
mv KPOINTS KPOINTSself
#INCAR_base
awk '{if($1=="ENMAX"){print $3}}' POTCAR > lsfile1
sed -i 's/;/ /g' lsfile1
echo `sort -n -r lsfile1` > lsfile2
allenmax=`awk '{print $1}' lsfile2`
enxs=`awk -v a=$allenmax 'BEGIN{printf("%d\n",1.5*a/10)}'`  #考虑1.5倍POTCAR里最大ENMAX作为ENCUT
enxs=$[enxs+1]
enmax=$[enxs*10]
cat > INCAR_base << EOF
SYSTEM = gaotongliang
ISTART = 0
ICHARG = 2
PREC = A
GGA_COMPAT = F
EDIFF = 1E-6
NPAR = 4
NELM = 480
ISMEAR = 0
SIGMA = 0.01
ENCUT = $enmax
LWAVE = F
LCHARG = T
LORBIT = 11
NBANDS = $nbands
EOF
cp ../vaspjob.sh ./
cp ../strong_corr ./
rm -f INCAR lsfile*
cd ../

#ucal dir
if [ ! -d $strcaldir ]; then
	mkdir $strcaldir
fi
cd $strcaldir
for ((iucal=1;iucal<=nucal;iucal++))  #对所有结构循环
do
	zu=${ulist[iucal-1]}
	zucalname="u"$zu
	if [ ! -d $zucalname ]; then
		mkdir $zucalname
	fi
	cd $zucalname
#zcalinput
	cp ../../zcalinput/* ./
#INCAR_u
awk 'BEGIN{printf "LDAUL = "}' > LDAULfile
awk 'BEGIN{printf "LDAUU = "}' > LDAUUfile
elename=(`sed -n 6p POSCAR`)
neletype=${#elename[*]}
for ((iele=1;iele<=neletype;iele++))
do
        zelement=${elename[iele-1]}
        check_corr=`awk -v zele=$zelement 'BEGIN{checkresult=0}{if($1==zele){checkresult=1;exit}}END{print checkresult}' strong_corr`
        if [ $check_corr -eq 1 ]; then
                awk 'BEGIN{printf "2 "}' >> LDAULfile
                awk -v zu=$zu 'BEGIN{printf zu" "}' >> LDAUUfile
        else
                awk 'BEGIN{printf "-1 "}' >> LDAULfile
                awk 'BEGIN{printf "0 "}' >> LDAUUfile
        fi
done
echo >> LDAULfile
echo >> LDAUUfile
cat > INCAR_u << EOF
LDAU = T
LMAXMIX = 4
EOF
cat INCAR_u LDAULfile LDAUUfile >lsfile
mv -f lsfile INCAR_u
#cat all INCAR_*
	cat INCAR_base INCAR_ncl INCAR_u >INCAR
#复制DFT计算任务脚本并提交
#该脚本完成自洽，能带以及topo check高对称点计算
	bsub < vaspjob.sh
	rm -f lsfile*
	cd ../
done
rm -f lsfile*
cd ../
#uhtcal 结束
#此时位于某一结构计算目录中

cd ../../
done


