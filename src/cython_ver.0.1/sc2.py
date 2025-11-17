#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
sc2.py - Main script for energy comparison in Monte Carlo simulation
"""

import os
import sys
from shutil import copyfile

# Import Cython functions
import sc2_unit

# Temperature in Kelvin
T_KELVIN = 298

def get_run_dir():
    """Get the run directory (caseA or template directory)"""
    current_dir = os.getcwd()
    # Assumes script is run from run/caseA/ or similar
    return current_dir

def setup_file_paths(run_dir):
    """Setup all file paths relative to run directory"""
    paths = {
        'FN_CURR': os.path.join(run_dir, 'data_curr_E'),
        'FN_NEW': os.path.join(run_dir, 'data_new_E'),
        'FN_OUT': os.path.join(run_dir, 'output_E'),
        'ST_CURR_G': os.path.join(run_dir, 'struct_curr_g.lmp'),
        'ST_NEW_G': os.path.join(run_dir, 'struct_new_g.lmp'),
        'ST_OPT': os.path.join(run_dir, 'curr_step', 'struct_opt.lmp'),
        'ST_CURR': os.path.join(run_dir, 'struct_curr.lmp'),
        'STRUCT_DIR': os.path.join(run_dir, 'results', 'structures'),
        'VAC_STRUCT_DIR': os.path.join(run_dir, 'results', 'vac_structures')
    }
    
    # Create directories if they don't exist
    os.makedirs(paths['STRUCT_DIR'], exist_ok=True)
    os.makedirs(paths['VAC_STRUCT_DIR'], exist_ok=True)
    
    return paths

def main():
    """Main function"""
    step_id = 0
    if len(sys.argv) > 1:
        step_id = int(sys.argv[1])
    
    # Get run directory and setup paths
    run_dir = get_run_dir()
    paths = setup_file_paths(run_dir)
    
    # Save optimized structure
    struct_file = os.path.join(paths['STRUCT_DIR'], f"{step_id:05d}_struct.lmp")
    copyfile(paths['ST_OPT'], struct_file)
    
    # Save structure with ghosts
    vac_struct_file = os.path.join(paths['VAC_STRUCT_DIR'], f"{step_id:05d}_struct_g.lmp")
    sc2_unit.insert_ghosts(paths['ST_OPT'], paths['ST_NEW_G'], vac_struct_file)
    
    # Compare energies
    acc = sc2_unit.compare_energy(
        T_KELVIN,
        paths['FN_CURR'],
        paths['FN_NEW'],
        paths['FN_OUT'],
        step_id
    )
    
    # If accepted, update current structures
    if acc:
        sc2_unit.insert_ghosts(paths['ST_OPT'], paths['ST_NEW_G'], paths['ST_CURR_G'])
        copyfile(paths['ST_OPT'], paths['ST_CURR'])
    
    return 0

if __name__ == '__main__':
    sys.exit(main())