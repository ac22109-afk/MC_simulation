# distutils: define_macros=NPY_NO_DEPRECATED_API=NPY_1_7_API_VERSION

import numpy as np
cimport numpy as np

np.import_array()

from random import randint
import random

# グローバル定数を定義（sc4.pyから取得）
DEF GHOST_TYPEID_DEFAULT = "4"
DEF N_GHOST_DEFAULT = 1

cpdef list read_struct_and_choose_pair(str fn, str GHOST_TYPEID=GHOST_TYPEID_DEFAULT, int N_GHOST=N_GHOST_DEFAULT):
    ''' Returns numbers of lines in the file to swap 
        dummy function
    '''

    cdef str anchor_atoms = "Atoms # atomic"
    cdef int nAtoms = 0
    cdef int nTypes = 0
    cdef int lineN = 0
    cdef np.ndarray[np.float64_t, ndim=1] vs = np.zeros(3, dtype=np.float64)
    cdef np.ndarray baseVs

    oldf = open(fn)

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
            vs[0] = float(cl.split()[1])
        if "ylo" in cl:
            vs[1] = float(cl.split()[1])
        if "zlo" in cl:
            vs[2] = float(cl.split()[1])
            baseVs = (np.identity(3, dtype=np.int64))*vs
        if anchor_atoms in cl:
            break

    print(f"nAtoms = {nAtoms}")

    if nTypes <= 1:
        print("!!! ERROR !!!")
        print("Should be more than 1 type")
        exit()

    ## --- reading all atoms
    cdef np.ndarray[np.int64_t, ndim=1] arrID = np.zeros((nAtoms), dtype=np.int64)
    cdef np.ndarray[np.int64_t, ndim=1] arrType = np.zeros((nAtoms), dtype=np.int64)
    cdef np.ndarray[np.int64_t, ndim=1] arrLineNum = np.zeros((nAtoms), dtype=np.int64)
    cdef np.ndarray[np.float64_t, ndim=2] arrR = np.zeros((nAtoms,3), dtype=np.float64)
    
    cl = oldf.readline()
    lineN += 1

    cdef np.ndarray[np.int64_t, ndim=1] vac_ID_list = np.zeros((N_GHOST), dtype=np.int64)
    cdef np.ndarray[np.int64_t, ndim=1] vac_Type_list = np.zeros((N_GHOST), dtype=np.int64)
    cdef np.ndarray[np.int64_t, ndim=1] vac_LineNum_list = np.zeros((N_GHOST), dtype=np.int64)
    cdef np.ndarray[np.float64_t, ndim=2] vac_arrR_list = np.zeros((N_GHOST,3), dtype=np.float64)
    cdef int vac_num = 0
    cdef int ghost_type_id = int(GHOST_TYPEID) 
    cdef int ia 
    for ia in range(nAtoms):
        cl = oldf.readline()
        lineN += 1
        cl_list = cl.split()
        if ("" == cl) or (len(cl_list) < 5):
            print("!!! ERROR !!!")
            print(f"File {fn} ended abruptly (cannot read atoms).")
            exit()
            
        arrID[ia] = int(cl_list[0])
        arrType[ia] = int(cl_list[1])
        arrLineNum[ia] = lineN
        arrR[ia] = [ float(cl_list[ix]) for ix in range(2,5) ]
        if arrType[ia] == ghost_type_id: 
            vac_ID_list[vac_num] = arrID[ia]
            vac_Type_list[vac_num] = arrType[ia]
            vac_LineNum_list[vac_num] = arrLineNum[ia]
            vac_arrR_list[vac_num] = arrR[ia]
            vac_num += 1
    oldf.close()

    cdef int randID1, randID2
    while True:
        randID1 = randint(0,nAtoms-1)
        randID2 = randint(0,nAtoms-1)
        if randID1 == randID2:
            continue
        if arrType[randID1] == arrType[randID2]:
            continue
        break

    return [[int(arrID[randID1]), int(arrType[randID1])],
            [int(arrID[randID2]), int(arrType[randID2])]]

cpdef bint check_types(np.ndarray[np.int64_t, ndim=1] arrType, bint do_exit=True):
    ''' throw error if all types are same '''
    cdef long max_tp = np.amax(arrType) 
    cdef long min_tp = np.amin(arrType)
    cdef bint all_similar = False
    if max_tp == min_tp:
        all_similar = True

    if all_similar and do_exit:
        print("!!! ERROR !!!")
        print("All atoms are of same type!")
        exit()
    return all_similar

cpdef void copy_and_swap_types(str fn_from, str fn_to, list atom_pair, bint do_print=False):
    ''' copy file 
        atom_pair = [[aid_0, atp_0], [aid_1, atp_1]]
    '''

    oldf = open(fn_from)
    newf = open(fn_to, 'w')

    cdef bint now_velocities = False
    cdef int i = 0
    cdef int ia, tp
    cdef bint found
    cdef list pp

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

            if found:
                clspl[0] = str(ia)
                clspl[1] = str(tp)
                cl = " ".join(clspl) + "\n"
        
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

cpdef void record_and_remove_vac(str fn_from, str fn_to, str GHOST_TYPEID=GHOST_TYPEID_DEFAULT, int N_GHOST=N_GHOST_DEFAULT):

    ghostf = open(fn_from)
    outf = open(fn_to,"w")

    cdef list vac_ids = []
    cdef int nAtoms, types

    while True:
        cl = ghostf.readline()
        cl_list = cl.split()
        if "" == cl:
            break
        elif " atoms" in cl:
            nAtoms = int(cl.split()[0])
            cl = f"{nAtoms - N_GHOST} atoms" + "\n"
        elif " types" in cl:
            types = int(cl.split()[0])
            cl = f"{types - 1} atom types" + "\n"
        if (len(cl_list) == 2) and (cl_list[0] == GHOST_TYPEID):
            continue
        elif (len(cl_list) > 1) and (cl_list[1] == GHOST_TYPEID):
            vac_ids.append(cl_list[0])
            continue
        elif (len(cl_list) == 4) and (cl_list[0] in vac_ids):
            continue
        outf.write(cl)
    outf.close()
    ghostf.close()