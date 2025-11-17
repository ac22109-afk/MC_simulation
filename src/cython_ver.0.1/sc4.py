#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
sc4.py - Main script for atom swapping in Monte Carlo simulation
"""

import os
import sys

# Import VASP module
sys.path.append("/work/02/gn29/n29001/opt/modules/")
from m_vasp_dc_368 import VaspPOSCAR

# Import Cython functions
import sc4_unit

# Constants
N_GHOST = 1
R_IN = 3.0

def get_run_dir():
    """Get the run directory (caseA or template directory)"""
    current_dir = os.getcwd()
    return current_dir

def setup_file_paths(run_dir):
    """Setup all file paths relative to run directory"""
    paths = {
        'FN_CURR': os.path.join(run_dir, 'struct_curr_g.lmp'),
        'FN_NEW_G': os.path.join(run_dir, 'struct_new_g.lmp'),
        'FN_NEW': os.path.join(run_dir, 'curr_step', 'struct.lmp')
    }
    
    return paths

def main():
    """Main function"""
    # Get run directory and setup paths
    run_dir = get_run_dir()
    paths = setup_file_paths(run_dir)
    
    # Read VASP structure
    vp = VaspPOSCAR.from_file(paths['FN_CURR'])
    
    # Read structure and choose pair
    atom_pair = sc4_unit.read_struct_and_choose_pair(paths['FN_CURR'], N_GHOST)
    
    print(f"Substitute atom[{atom_pair[0][0]}] of type[{atom_pair[0][1]}] with" +
          f" atom[{atom_pair[1][0]}] of type[{atom_pair[1][1]}]")
    
    print(f"Atom [{atom_pair[1][0]}] z = {vp.arr_r[atom_pair[1][0]-1, 2]}")
    
    # Copy and swap types
    sc4_unit.copy_and_swap_types(paths['FN_CURR'], paths['FN_NEW_G'], atom_pair, do_print=True)
    
    # Remove ghost atoms
    sc4_unit.record_and_remove_vac(paths['FN_NEW_G'], paths['FN_NEW'], N_GHOST)
    
    print("")
    print("Done")
    print("")
    
    return 0

if __name__ == '__main__':
    sys.exit(main())