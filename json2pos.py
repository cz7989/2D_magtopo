from pymatgen.core import Structure
import json

with open('zstrjson') as f:
   zstrlist=json.load(f)

zstrid=zstrlist['material_id']
zstruct=Structure.from_dict(zstrlist['structure'])
zstruct.to(filename='POSCAR_'+zstrid)

