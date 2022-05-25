#!/bin/sh
#BSUB -J db2pos
#BSUB -n 32
#BSUB -q 6226rib!

hs=`awk 'END{print NR}' db.json`
for ((i=1;i<=hs;i++))
do
	sed -n "$i"p db.json >zstrjson
	python json2pos.py
	mv -v POSCAR_* poscar_fromdb
done
