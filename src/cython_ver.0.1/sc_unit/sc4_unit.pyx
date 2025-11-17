# cython: language_level=3
# sc4_unit.pyx

import numpy as np
cimport numpy as cnp
from libc.stdlib cimport rand, RAND_MAX
import cython

# Initialize numpy
cnp.import_array()

cdef int randint_c(int low, int high):
    """Generate random integer between low and high-1"""
    return low + (rand() % (high - low))

GHOST_TYPEID = "4"

@cython.boundscheck(False)
@cython.wraparound(False)
def read_struct_and_choose_pair(str fn, int n_ghost):
    """Read structure and choose atom pair to swap"""
    cdef:
        int nAtoms = 0, nTypes = 0, lineN = 0, ia, vac_num = 0
        int randID1, randID2
        double x_vs, y_vs, z_vs
        list cl_list
        str cl, anchor_atoms = "Atoms # atomic"
    
    cdef cnp.ndarray[cnp.int32_t, ndim=1] arrID
    cdef cnp.ndarray[cnp.int32_t, ndim=1] arrType
    cdef cnp.ndarray[cnp.int32_t, ndim=1] arrLineNum
    cdef cnp.ndarray[cnp.float64_t, ndim=2] arrR
    cdef cnp.ndarray[cnp.float64_t, ndim=1] vs = np.zeros(3, dtype=np.float64)
    
    # Read file header
    with open(fn, 'r') as oldf:
        while True:
            cl = oldf.readline()
            lineN += 1
            if cl == "":
                break
            if "atoms" in cl:
                nAtoms = int(cl.split()[0])
            if "types" in cl:
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
            if anchor_atoms in cl:
                break
        
        print(f"nAtoms = {nAtoms}")
        
        if nTypes <= 1:
            raise ValueError("Should be more than 1 type")
        
        # Initialize arrays
        arrID = np.zeros(nAtoms, dtype=np.int32)
        arrType = np.zeros(nAtoms, dtype=np.int32)
        arrLineNum = np.zeros(nAtoms, dtype=np.int32)
        arrR = np.zeros((nAtoms, 3), dtype=np.float64)
        
        # Skip blank line
        cl = oldf.readline()
        lineN += 1
        
        # Read atoms
        for ia in range(nAtoms):
            cl = oldf.readline()
            lineN += 1
            cl_list = cl.split()
            if (cl == "") or (len(cl_list) < 5):
                raise ValueError(f"File {fn} ended abruptly (cannot read atoms).")
            
            arrID[ia] = int(cl_list[0])
            arrType[ia] = int(cl_list[1])
            arrLineNum[ia] = lineN
            arrR[ia, 0] = float(cl_list[2])
            arrR[ia, 1] = float(cl_list[3])
            arrR[ia, 2] = float(cl_list[4])
    
    # Choose random pair with different types
    while True:
        randID1 = randint_c(0, nAtoms)
        randID2 = randint_c(0, nAtoms)
        if randID1 == randID2:
            continue
        if arrType[randID1] == arrType[randID2]:
            continue
        break
    
    return [[int(arrID[randID1]), int(arrType[randID1])],
            [int(arrID[randID2]), int(arrType[randID2])]]

def copy_and_swap_types(str fn_from, str fn_to, list atom_pair, bint do_print=False):
    """Copy file and swap atom types"""
    cdef:
        int i = 0, ia, tp
        bint now_velocities = False, found
        str cl
        list clspl, pp
    
    with open(fn_from, 'r') as oldf:
        with open(fn_to, 'w') as newf:
            while True:
                cl = oldf.readline()
                i += 1
                if cl == "":
                    break
                
                clspl = cl.split()
                
                # Swap atom IDs and types
                if (len(clspl) > 4) and (i > 5):
                    ia = int(clspl[0])
                    tp = int(clspl[1])
                    found = False
                    
                    for pp in [[0, 1], [1, 0]]:
                        if ia == atom_pair[pp[0]][0]:
                            ia = atom_pair[pp[1]][0]
                            tp = atom_pair[pp[1]][1]
                            found = True
                            break
                    
                    if found:
                        clspl[0] = str(ia)
                        clspl[1] = str(tp)
                        cl = " ".join(clspl) + "\n"
                
                # Check for Velocities section
                if cl.startswith("Velocities"):
                    now_velocities = True
                
                # Swap velocity IDs
                if (len(clspl) == 4) and now_velocities:
                    ia = int(clspl[0])
                    for pp in [[0, 1], [1, 0]]:
                        if ia == atom_pair[pp[0]][0]:
                            ia = atom_pair[pp[1]][0]
                            clspl[0] = str(ia)
                            cl = " ".join(clspl) + "\n"
                            break
                
                newf.write(cl)

def record_and_remove_vac(str fn_from, str fn_to, int n_ghost):
    """Remove ghost atoms from structure file"""
    cdef:
        list vac_ids = []
        list cl_list
        str cl, ghost_typeid = GHOST_TYPEID
        int nAtoms, types
    
    with open(fn_from, 'r') as ghostf:
        with open(fn_to, 'w') as outf:
            while True:
                cl = ghostf.readline()
                cl_list = cl.split()
                
                if cl == "":
                    break
                elif " atoms" in cl:
                    nAtoms = int(cl.split()[0])
                    cl = f"{nAtoms - n_ghost} atoms\n"
                elif " types" in cl:
                    types = int(cl.split()[0])
                    cl = f"{types - 1} atom types\n"
                
                # Skip ghost mass definition
                if (len(cl_list) == 2) and (cl_list[0] == ghost_typeid):
                    continue
                # Skip ghost atoms
                elif (len(cl_list) > 1) and (cl_list[1] == ghost_typeid):
                    vac_ids.append(cl_list[0])
                    continue
                # Skip ghost velocities
                elif (len(cl_list) == 4) and (cl_list[0] in vac_ids):
                    continue
                
                outf.write(cl)