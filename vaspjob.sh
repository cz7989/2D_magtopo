#!/bin/sh
#BSUB -J vaspjob
#BSUB -n 32
#BSUB -q 6226rib!

#scf+bands+si*********************
#需要KPOINTSself,KPOINTSbands,KPOINTSsi,POSCAR,POTCAR和INCAR
if [ ! -d "scf_result" ]; then
  mkdir scf_result
fi
if [ ! -d "bands_result" ]; then
  mkdir bands_result
fi
if [ ! -d "dos_result" ]; then
  mkdir dos_result
fi
if [ ! -d "si_result" ]; then
  mkdir si_result
fi

cp KPOINTSself KPOINTS
awk '{if($1=="ISTART"){printf "ISTART = 0\n"}else if($1=="ICHARG"){printf "ICHARG = 2\n"}else if($1=="LWAVE"){printf "LWAVE = F\n"}else if($1=="LCHARG"){printf "LCHARG = T\n"}else{printf $0"\n"}}' INCAR > ls
mv ls INCAR
mpirun vasp_ncl
cp INCAR scf_result/
cp KPOINTS scf_result/
cp POSCAR scf_result/
cp DOSCAR scf_result/
cp EIGENVAL scf_result/
cp OUTCAR scf_result/
cp CHGCAR scf_result/

cp KPOINTSsi KPOINTS
awk '{if($1=="ISTART"){printf "ISTART = 0\n"}else if($1=="ICHARG"){printf "ICHARG = 11\n"}else if($1=="LCHARG"){printf "LCHARG = F\n"}else if($1=="LWAVE"){printf "LWAVE = T\n"}else{printf $0"\n"}}' INCAR > ls
mv ls INCAR
mpirun vasp_ncl
cp INCAR si_result/
cp KPOINTS si_result/
cp POSCAR si_result/
cp EIGENVAL si_result/
cp OUTCAR si_result/
mv WAVECAR si_result/

cp KPOINTSbands KPOINTS
awk '{if($1=="ISTART"){printf "ISTART = 0\n"}else if($1=="ICHARG"){printf "ICHARG = 11\n"}else if($1=="LCHARG"){printf "LCHARG = F\n"}else if($1=="LWAVE"){printf "LWAVE = F\n"}else{printf $0"\n"}}' INCAR > ls
mv ls INCAR
mpirun vasp_ncl
cp INCAR bands_result/
cp KPOINTS bands_result/
cp POSCAR bands_result/
cp DOSCAR bands_result/
mv EIGENVAL bands_result/
mv OUTCAR bands_result/
mv PROCAR bands_result/

cp KPOINTSself KPOINTS
mpirun vasp_ncl
cp INCAR dos_result/
cp KPOINTS dos_result/
cp POSCAR dos_result/
cp DOSCAR dos_result/
mv EIGENVAL dos_result/
mv OUTCAR dos_result/
mv PROCAR dos_result/
#******************************

rm -f vasprun.xml

