#!/usr/bin/env python

#from symbol import atom
# import sys
# sys.path.append("04_pbc_gr/modules")

import sys
sys.path.append("/work/02/gn29/n29001/opt/modules/")

from m_vasp_dc_368 import VaspPOSCAR

from random import randint
import random
import numpy as np

from m_geom import prepare_box,\
                   v_in_peridoc_box

FN_CURR  = "struct_curr_g.lmp"
FN_NEW_G = "struct_new_g.lmp"
FN_NEW   = "curr_step/struct.lmp"

GHOST_TYPEID = "4"

R_IN = 3.0

N_GHOST = 1

## ---------------------------  MAIN --------------------------- ##

def main():

	vp = VaspPOSCAR.from_file(FN_CURR)

	## read file and get pair
	## atom_pair [ [id,type], [id,type] ]
	atom_pair = read_struct_and_choose_pair(FN_CURR)

	print(f"Substitute atom[{atom_pair[0][0]}] of type[{atom_pair[0][1]}] with"+\
		 f" atom[{atom_pair[1][0]}] of type[{atom_pair[1][1]}]")

	print(f"Atom [{atom_pair[1][0]}] z = {vp.arr_r[atom_pair[1][0]-1, 2]}")

	copy_and_swap_types(FN_CURR, FN_NEW_G, atom_pair, do_print=True)

	record_and_remove_vac(FN_NEW_G, FN_NEW)

	# print("")
	# print("Done")
	# print("")

## --------------------------- FUNCS --------------------------- ##

def read_struct_and_choose_pair(fn):
	''' Returns numbers of lines in the file to swap 
	    dummy function
	'''

	anchor_atoms = "Atoms # atomic"
	nAtoms = 0
	nTypes = 0

	oldf = open(fn)#FN_CURR,struct_curr_g

	lineN = 0
	vs = np.zeros(3, float)
	while True:
		cl = oldf.readline()
		lineN += 1
		if "" == cl:
			break
		if "atoms" in cl:
			nAtoms = int(cl.split()[0])
		if "types" in cl :
			nTypes = int(cl.split()[0])
		if "xlo" in cl:
			x_vs = float(cl.split()[1])
			vs[0] = x_vs
		if "ylo" in cl:
			y_vs = float(cl.split()[1])
			vs[1] = y_vs
		if "zlo" in cl:
			z_vs = float(cl.split()[1])
			vs[2] = z_vs
			baseVs = (np.identity(3, int))*vs
		if anchor_atoms in cl:
			break

	print(f"nAtoms = {nAtoms}")

	if nTypes <= 1:
		print("!!! ERROR !!!")
		print("Should be more than 1 type")
		exit()

	## >>>>>>> DEBUG BEGIN
	#print(baseVs)
	## >>>>>>> DEBUG END 

	## --- reading all atoms
	arrID = np.zeros((nAtoms), int)
	arrType = np.zeros((nAtoms), int)
	arrLineNum = np.zeros((nAtoms), int)
	arrR = np.zeros((nAtoms,3), float)
	cl = oldf.readline()
	lineN += 1


	## >>>>>>> DEBUG BEGIN
	vac_ID_list = np.zeros((N_GHOST), int)
	vac_Type_list = np.zeros((N_GHOST), int)
	vac_LineNum_list = np.zeros((N_GHOST), int)
	vac_arrR_list = np.zeros((N_GHOST,3), float)
	vac_num = 0


	for ia in range(nAtoms):
		cl = oldf.readline()
		lineN += 1
		cl_list = cl.split()
		if ("" == cl) or (len(cl_list) < 5):
			print("!!! ERROR !!!")
			print(f"File {fn} ended abruptly (cannot read atoms).")
			exit()
			break
		arrID[ia] = int(cl_list[0])
		arrType[ia] = int(cl_list[1])
		arrLineNum[ia] = lineN
		arrR[ia] = [ float(cl_list[ix]) for ix in range(2,5) ]
		if arrType[ia] == int(GHOST_TYPEID):
			vac_ID_list[vac_num] = arrID[ia]
			vac_Type_list[vac_num] = arrType[ia]
			vac_LineNum_list[vac_num] = arrLineNum[ia]
			vac_arrR_list[vac_num] = arrR[ia]
			vac_num += 1
	oldf.close()

	while True:
		randID1 = randint(0,nAtoms-1)
		randID2 = randint(0,nAtoms-1)
		if randID1 == randID2:
			continue
		if arrType[randID1] == arrType[randID2]:
			continue
		break

	return [[arrID[randID1],arrType[randID1]],\
			[arrID[randID2],arrType[randID2]]]
	
def check_types(arrType, do_exit=True):
	''' throw error if all types are same '''
	max_tp = np.amax(arrType)
	min_tp = np.amin(arrType)
	all_similar = False
	if max_tp == min_tp:
		all_similar = True

	if all_similar and do_exit:
		print("!!! ERROR !!!")
		print("All atoms are of same type!")
		exit()

	# print(arrType)

	return all_similar

def copy_and_swap_types(fn_from, fn_to, atom_pair, do_print=False):
	''' copy file 
	    atom_pair = [[aid_0, atp_0], [aid_1, atp_1]]
	'''

	oldf = open(fn_from)# FN_CURR,struct_curr_g.lmp
	newf = open(fn_to, 'w')# FN_NEW_G,struct_new_g.lmp

	now_velocities = False

	i = 0
	while True:
		cl = oldf.readline()
		i += 1
		if "" == cl:
			break
		clspl = cl.split()
		if (len(clspl) > 4) and (i > 5):
			ia = int(clspl[0])
			tp = int(clspl[1])
			found = False
			for pp in [ [0,1], [1,0] ]:
				if ia == atom_pair[pp[0]][0]:
					ia = atom_pair[pp[1]][0]
					tp = atom_pair[pp[1]][1]
					found = True
					break
			##
			# if do_print and found:
			# 	# print("INITIAL" + "=" * 15)
			# 	# print(cl[:-1])
			
			if found:
				clspl[0] = str(ia)
				clspl[1] = str(tp)
				cl = " ".join(clspl) + "\n"

			# if do_print and found:
			# 	# print("FINAL")
			# 	# print(cl[:-1])
			# 	# print("=" * 15)
		
		if cl.startswith("Velocities"):
			now_velocities = True
		
		if (len(clspl) == 4) and now_velocities:
			ia = int(clspl[0])
			found = False
			for pp in [ [0,1], [1,0] ]:
				if ia == atom_pair[pp[0]][0]:
					ia = atom_pair[pp[1]][0]
					clspl[0] = str(ia)
					cl = " ".join(clspl) + "\n"
					break

		newf.write(cl)
	newf.close()
	oldf.close()

def record_and_remove_vac(fn_from, fn_to):


	ghostf = open(fn_from)#FN_NEW_G, struct_new_g
	outf = open(fn_to,"w")#FN_NEW, curr_step/struct

	vac_ids = []

	while True:
		cl = ghostf.readline()
		cl_list = cl.split()
		#print(cl_list)
		if "" == cl:
			#print("break")
			break
		elif " atoms" in cl:
			nAtoms = int(cl.split()[0])
			cl = f"{nAtoms - N_GHOST} atoms" + "\n"
		elif " types" in cl:
			types = int(cl.split()[0])
			cl = f"{types - 1} atom types" + "\n"
		if (len(cl_list) == 2) and (cl_list[0] == GHOST_TYPEID):
			## ------- check the mass
			continue
		elif (len(cl_list) > 1) and (cl_list[1] == GHOST_TYPEID):
			vac_ids.append(cl_list[0])
			continue
		elif (len(cl_list) == 4) and (cl_list[0] in vac_ids):
			continue
		outf.write(cl)
	outf.close()
	ghostf.close()
	

## --------------------------i- HOOK --------------------------- ##

if __name__ == '__main__':
	main()



