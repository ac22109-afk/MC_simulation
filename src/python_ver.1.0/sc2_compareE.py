from shutil import copyfile
from math import exp
from random import random
from sys import argv
import sys
import configparser
import os

# read config.ini(file,path info)
config_path = '../../config.ini'
if len(argv) > 2: 
    config_path = argv[2] #argv[1] mean step id,argv[2] mean config

config = configparser.ConfigParser()
if not os.path.exists(config_path):
    print(f"Error: Config file '{config_path}' not found")
    sys.exit(1)
config.read(config_path)

# module path
sys.path.append(config['paths']['module_path'])

FN_CURR = config['files_sc2']['fn_curr']
FN_NEW = config['files_sc2']['fn_new']
FN_OUT = config['files_sc2']['fn_out']
ST_CURR_G = config['files_sc2']['st_curr_g']
ST_NEW_G = config['files_sc2']['st_new_g']
ST_OPT = config['files_sc2']['st_opt']
ST_CURR = config['files_sc2']['st_curr']
#if you wanna change file path,edit config

T_Kelbin = 298


## ---------------------------  MAIN --------------------------- ##

def main():

    step_id = 0
    if len(argv) > 1:
        step_id = int(argv[1])

    copyfile(ST_OPT, f"structures/{step_id:05d}_struct.lmp")
    insert_ghosts(ST_OPT, ST_NEW_G, f"vac_structures/{step_id:05d}_struct_g.lmp")

    acc = compare_energy(T_Kelbin, FN_CURR, FN_NEW, FN_OUT, step_id)

    if acc :
        insert_ghosts(ST_OPT, ST_NEW_G, ST_CURR_G)
        copyfile(ST_OPT, ST_CURR)


## --------------------------- FUNCS --------------------------- ##


def read_energy(fn,fn_new):

    curr = open(fn)
    new = open(fn_new)

    #read_curr_energy
    curr.readline()
    cl1 = curr.readline()
    cl1_list = cl1.split()
    curr_E = float(cl1_list[2])
    print(f"current_E = {curr_E:12.7f}")

    #read_new_energy
    new.readline()
    cl2 = new.readline()
    cl2_list = cl2.split()
    new_E = float(cl2_list[2])
    print(f"new_E = {new_E:12.7f}")
    curr.close()
    new.close()
    return curr_E, new_E



def compare_energy(T, fn_curr, fn_new, fn_out, step_id):

    curr_E, new_E = read_energy(fn_curr, fn_new)

    out_E = open(fn_out,"a")

    k = 8.617333262*1e-5
    dE = new_E - curr_E
    argument = (-1)*(dE)/(k*int(T))
    i = 0
    acc = False

    if argument > 0:
        acc = True
    else:
        print("Calculate probability")
        boltman = exp(argument)
        r = random()
        print(f" dE = {dE:12.7f}  boltman = {boltman:8.6f} r = {r:8.6f}")
        acc = (boltman > r)

    if acc:
        print("+"*20 + " accepted")
        curr_E = new_E
        currf = open(fn_curr,"w")

        ## --- update E file
        ## a - append
        ## w - write
        ## r - read
        currf.write("# current E\n" + f" optimized E  {curr_E} " + "\n")
        out_E.write(f" {step_id:5d}  {new_E:15.7f}  accepted" + "\n")
        out_E.close()
    else:
        print("-"*20 + "rejected")
        out_E = open(fn_out,"a")
        out_E.write(f" {step_id:5d}  {new_E:15.7f}  rejected" + "\n")
        out_E.close()

    return acc


def insert_ghosts(st_opt, st_new_g, st_curr_g):

    n_ghost = 0
    ghost = []
    ghost_ID = []
    vlo_ghost = []

    info = open(st_new_g)
    while True:
        cl4 = info.readline()
        cl4_list = cl4.split()
        if "" == cl4:
            break
        if (len(cl4_list) > 4) and (cl4_list[1] == "4"):
            ghost.append(cl4.rstrip("\n"))
            n_ghost += 1
            ghost_ID.append(cl4_list[0])
        if (2<len(cl4_list)<5) and (cl4_list[0] in ghost_ID):
            vlo_ghost.append(cl4.rstrip("\n"))
    info.close()

    curr_g = open(st_curr_g,"w")
    opt = open(st_opt)

    # --- Add a state flag ---
    in_masses_section = False
    # -----------------------------

    while True:
        cl3 = opt.readline()
        if "" == cl3:
            break

        # --- Detect the start and end of the Masses section ---
        if "Masses" in cl3:
            in_masses_section = True
        
        if "Atoms" in cl3:
            in_masses_section = False
        # ---------------------------------------------------------

        if "atoms" in cl3:
            nAtoms = int(cl3.split()[0])
            cl3 = f"{nAtoms + n_ghost} atoms" + "\n"     
        if "atom types" in cl3:
            nType = int(cl3.split()[0])
            cl3 = f"{nType + 1} atom types" + "\n"
        
        # --- Check the flag and use a stricter condition ---
        if in_masses_section and cl3.strip().startswith("3 28.09"):
            cl3 = "3 28.09" + "\n" +"4 10.00" + "\n"
        # ----------------------------------------------------

        if "Atoms # atomic" in cl3:
            cl3 = opt.readline()
            cl3 = "Atoms # atomic"+ "\n"  + "\n"
            for ig in range(n_ghost):
                cl3 += ghost[ig] + "\n"
        if "Velocities" in cl3:
            cl3 = opt.readline()
            cl3 = "Velocities" + "\n"+ "\n"
            for ig in range(n_ghost):
                cl3 += vlo_ghost[ig] + "\n"
        curr_g.write(cl3)
    opt.close()
    curr_g.close()

## --------------------------- HOOK --------------------------- ##

if __name__ == '__main__':
	main()


## <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# if index_accept == 1:
#     # opt = open(st_opt)
#     # new_g = open(st_new_g)
#     copyfile("struct_new.lmp", "struct_curr_g.lmp")
#     copyfile("curr_step/struct_opt.lmp", "struct_curr.lmp")

#     copyfile("curr_step/struct_opt.lmp", "struct_curr.lmp")

#     #copyfile("struct_curr_g.lmp", f"vac_structures/{step_id:05d}_struct.lmp")
    
#     structf = open(f"vac_structures/{step_id:05d}_struct.lmp","w")
#     curr_g = open("struct_curr_g.lmp")
#     while True:
#         cl = curr_g.readline()
#         if "" == cl:
#             break
#         if "types" in cl :
#             nTypes = int(cl.split()[0])
#             cl = f"{nTypes + n_ghost} atom types" + "\n"
#         if len(cl.split()) == 2 and "3 28.09" in cl:
#             cl = "3 28.09" + "\n" + "4 00.00" + "\n"
#         structf.write(cl)

# if index_reject == 1:
#     copyfile("struct_new_g.lmp", f"vac_structures/{step_id:05d}_struct.lmp")