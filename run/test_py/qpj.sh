#!/bin/bash
#
#PJM -g gn29
#PJM -L rscgrp=regular-o
#PJM -L elapse=48:00:00
#PJM -L node=20
#PJM --mpi "proc=144"
#SBATCH --job-name=test-conda
#SBATCH --output=log.txt

cd $PJM_O_WORKDIR

# --- module ---
source /etc/profile.d/modules.sh
module use /work/opt/local/modules/modulefiles/LN/odyssey/compiler

# NumPy Python
# module load python/3.6.8

VENV_PATH="/work/02/gn29/n29001/MC_simulation/.venv"
if [ -f "${VENV_PATH}/bin/activate" ]; then
    export PYTHONNOUSERSITE=0
    source ${VENV_PATH}/bin/activate
    echo "Virtual environment activated: ${VENV_PATH}"
else
    echo "ERROR: Virtual environment not found at ${VENV_PATH}"
    exit 1
fi

py="${VENV_PATH}/bin/python"

lmp="/work/02/gn29/n29001/bin/lmp_mpi"

export LAMMPSPATH=/work/02/gn29/n29001/bin/lmp_mpi:$LAMMPSPATH

SRC_DIR="$PJM_O_WORKDIR/../../src"
MODULE_DIR="/work/02/gn29/n29001/opt/modules"

SYSTEM_NUMPY_PATH="/usr/lib64/python3.6/site-packages"


export PYTHONPATH="${SRC_DIR}:${MODULE_DIR}:${SYSTEM_NUMPY_PATH}:${PYTHONPATH}"

# Debug
hasDebug=#True

if [ "${hasDebug}" == "True" ];then
	echo "=== Debug Info ==="
	echo "HOST: $(hostname)"
	echo "PWD : $(pwd)"
	echo "VENV: ${VENV_PATH}"
	echo "SRC_DIR: ${SRC_DIR}"
	echo "MODULE_DIR: ${MODULE_DIR}"
	echo "PYTHONPATH: ${PYTHONPATH}"
	echo "--- SRC_DIR contents ---"
	ls -la ${SRC_DIR} 2>&1 || echo "SRC_DIR not found"
	echo "--- MODULE_DIR contents ---"
	ls -la ${MODULE_DIR} 2>&1 || echo "MODULE_DIR not found"
	echo "--------------------------------"
	echo "Target Python (\$py): $py"
	echo "Which Python: $(which python)"
	echo "--- Versions ---"
	$py --version
	$py -c "import numpy; print(f'NumPy Version: {numpy.__version__}')" || echo "NumPy not found in $py"
	$py -c "import sys; print(f'Actual Executable: {sys.executable}')"
	echo "=================="
	# Test Python imports before starting main calculation
	echo "=== Testing Python imports ==="
	$py -c "import sc2_unit; from m_vasp_dc_368 import VaspPOSCAR; print('Import successful')"
	$py -c "import sc2_unit; import sc4_unit; print('Import successful')"
	echo "=============================="
fi

## --- params
n_mc_steps=10000

if [ -f .tmp ]; then
	rm .tmp
fi

if [ -f output_E ]; then
	rm output_E
fi

# Create result directories (sc2.py creates these too, but just in case)
if [ ! -d results ]; then
	mkdir results
fi

if [ ! -d results/structures ]; then
	mkdir -p results/structures
fi

if [ ! -d results/vac_structures ]; then
	mkdir -p results/vac_structures
fi

# Backward compatibility: create symlinks if old directory names exist
if [ ! -d structures ] && [ -d results/structures ]; then
	ln -s results/structures structures
fi

if [ ! -d vac_structures ] && [ -d results/vac_structures ]; then
	ln -s results/vac_structures vac_structures
fi

# read config.ini 
CONFIG_FILE="../../config.ini"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file '$CONFIG_FILE' not found"
    exit 1
fi

## --- files
FNLOG="all.log"
echo "Start calculations" > $FNLOG

cp struct_zero.lmp struct_curr.lmp
cp struct_zero_g.lmp struct_curr_g.lmp

i=0
echo "" >> $FNLOG
info="============================= Step $i"
echo $info >> $FNLOG
## --- run lammps
cp struct_curr.lmp curr_step/struct.lmp
cd "curr_step/"
mpiexec -n 144 $lmp -in IN.lammps >> .tmp
cd ../
mv data_new_E data_curr_E
tail -1 data_curr_E >> $FNLOG

for i in `seq 1 $n_mc_steps`; do
	j=`expr $i % 100`
	if [ $j -eq 0 ]; then suff="ONLY E"; else suff="OPTIMIZE"; fi

	echo "" >> $FNLOG
	info="============================= Step $i $suff"
	echo $info >> $FNLOG

	## --- swap atoms
	$py $SRC_DIR/sc4.py "$CONFIG_FILE" >> $FNLOG 

	# --- run minimize lammps
	if [ $j -eq 0 ]; then
		cd "curr_step/"
		mpiexec -n 144 $lmp -in IN.lammps >> .tmp
		cd ../
	else
		cd "curr_step/"
		mpiexec -n 144 $lmp -in IN.minimize.lammps >> .tmp
		cd ../
	fi

	# cp curr_step/struct_opt.lmp interm/struct_opt_$i.lmp

	## --- compare E
	$py $SRC_DIR/sc2.py $i "$CONFIG_FILE" >> $FNLOG
done

# ============== rename _curr to _zero ==================
# Copy final structure for the next run
cp struct_curr.lmp   struct_zero.lmp
cp struct_curr_g.lmp struct_zero_g.lmp

echo "Calculation completed successfully!" >> $FNLOG