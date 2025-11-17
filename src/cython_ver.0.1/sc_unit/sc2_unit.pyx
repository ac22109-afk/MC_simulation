# cython: language_level=3
# sc2_unit.pyx

from libc.math cimport exp
from libc.stdlib cimport rand, RAND_MAX
from libc.stdio cimport fopen, fclose, fprintf, FILE
import cython

cdef double random_uniform():
    """Generate random number between 0 and 1"""
    return <double>rand() / <double>RAND_MAX

@cython.boundscheck(False)
@cython.wraparound(False)
def read_energy(str fn_curr, str fn_new):
    """Read energy values from two files"""
    cdef double curr_E, new_E
    
    # Read current energy
    with open(fn_curr, 'r') as curr:
        curr.readline()
        cl1 = curr.readline()
        cl1_list = cl1.split()
        curr_E = float(cl1_list[2])
    
    print(f"current_E = {curr_E:12.7f}")
    
    # Read new energy
    with open(fn_new, 'r') as new:
        new.readline()
        cl2 = new.readline()
        cl2_list = cl2.split()
        new_E = float(cl2_list[2])
    
    print(f"new_E = {new_E:12.7f}")
    
    return curr_E, new_E

@cython.cdivision(True)
def compare_energy(double T, str fn_curr, str fn_new, str fn_out, int step_id):
    """Compare energies and decide acceptance using Metropolis criterion"""
    cdef double curr_E, new_E, k, dE, argument, boltman, r
    cdef bint acc = False
    
    curr_E, new_E = read_energy(fn_curr, fn_new)
    
    k = 8.617333262e-5
    dE = new_E - curr_E
    argument = (-1.0) * dE / (k * T)
    
    if argument > 0:
        acc = True
    else:
        print("Calculate probability")
        boltman = exp(argument)
        r = random_uniform()
        print(f" dE = {dE:12.7f}  boltman = {boltman:8.6f} r = {r:8.6f}")
        acc = (boltman > r)
    
    # Write results
    with open(fn_out, 'a') as out_E:
        if acc:
            print("+" * 20 + " accepted")
            with open(fn_curr, 'w') as currf:
                currf.write("# current E\n")
                currf.write(f" optimized E  {new_E} \n")
            out_E.write(f" {step_id:5d}  {new_E:15.7f}  accepted\n")
        else:
            print("-" * 20 + "rejected")
            out_E.write(f" {step_id:5d}  {new_E:15.7f}  rejected\n")
    
    return acc

def insert_ghosts(str st_opt, str st_new_g, str st_curr_g):
    """Insert ghost atoms into structure file"""
    cdef int n_ghost = 0
    cdef list ghost = []
    cdef list ghost_ID = []
    cdef list vlo_ghost = []
    cdef bint in_masses_section = False
    cdef int nAtoms, nType
    
    # Read ghost information from st_new_g
    with open(st_new_g, 'r') as info:
        while True:
            cl4 = info.readline()
            if cl4 == "":
                break
            cl4_list = cl4.split()
            if (len(cl4_list) > 4) and (cl4_list[1] == "4"):
                ghost.append(cl4.rstrip("\n"))
                n_ghost += 1
                ghost_ID.append(cl4_list[0])
            if (2 < len(cl4_list) < 5) and (cl4_list[0] in ghost_ID):
                vlo_ghost.append(cl4.rstrip("\n"))
    
    # Write modified structure
    with open(st_curr_g, 'w') as curr_g:
        with open(st_opt, 'r') as opt:
            while True:
                cl3 = opt.readline()
                if cl3 == "":
                    break
                
                # Detect Masses section
                if "Masses" in cl3:
                    in_masses_section = True
                
                if "Atoms" in cl3:
                    in_masses_section = False
                
                # Modify atom count
                if "atoms" in cl3:
                    nAtoms = int(cl3.split()[0])
                    cl3 = f"{nAtoms + n_ghost} atoms\n"
                
                # Modify type count
                if "atom types" in cl3:
                    nType = int(cl3.split()[0])
                    cl3 = f"{nType + 1} atom types\n"
                
                # Add ghost mass
                if in_masses_section and cl3.strip().startswith("3 28.09"):
                    cl3 = "3 28.09\n4 10.00\n"
                
                # Insert ghost atoms
                if "Atoms # atomic" in cl3:
                    opt.readline()
                    cl3 = "Atoms # atomic\n\n"
                    for ig in range(n_ghost):
                        cl3 += ghost[ig] + "\n"
                
                # Insert ghost velocities
                if "Velocities" in cl3:
                    opt.readline()
                    cl3 = "Velocities\n\n"
                    for ig in range(n_ghost):
                        cl3 += vlo_ghost[ig] + "\n"
                
                curr_g.write(cl3)