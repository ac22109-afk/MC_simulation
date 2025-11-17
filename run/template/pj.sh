#!/bin/sh
#
#PJM -g gn29
#PJM -L rscgrp=regular-o
#PJM -L elapse=48:00:00
#PJM -L node=20
#PJM --mpi "proc=144"
#SBATCH --job-name=test-conda
#SBATCH --output=log.txt

cd $PJM_O_WORKDIR

source /etc/profile.d/modules.sh
module use /work/opt/local/modules/modulefiles/LN/odyssey/compiler

export LAMMPSPATH=/work/02/gn29/n29001/bin/lmp_mpi:$LAMMPSPATH

# --- ディレクトリパスの設定 ---
# PJM_O_WORKDIR は /.../run/caseA を指します
SRC_DIR=$PJM_O_WORKDIR/../../src # srcディレクトリへのパス
MODULE_DIR=/work/02/gn29/n29001/opt/modules # 外部モジュールディレクトリ

# Pythonモジュール検索パスの設定
# - SRC_DIR: sc2_unit.so, sc4_unit.so などのプロジェクト固有モジュール用
# - MODULE_DIR: m_vasp_dc_368 などの共通ユーティリティモジュール用
export PYTHONPATH=${SRC_DIR}:${MODULE_DIR}:${PYTHONPATH}

echo "=== Debug Info ==="
echo "HOST: $(hostname)"
echo "PWD : $(pwd)"
echo "SRC_DIR: ${SRC_DIR}"
echo "MODULE_DIR: ${MODULE_DIR}"
echo "PYTHONPATH: ${PYTHONPATH}"
echo "--- SRC_DIR contents ---"
ls -la ${SRC_DIR} 2>&1 || echo "SRC_DIR not found"
echo "--- MODULE_DIR contents ---"
ls -la ${MODULE_DIR} 2>&1 || echo "MODULE_DIR not found"
echo "=================="

## --- params
n_mc_steps=10000

py="/usr/bin/python"
lmp="/work/02/gn29/n29001/bin/lmp_mpi"

# Test Python imports before starting main calculation
echo "=== Testing Python imports ==="
$py -c "import sc2_unit; import sc4_unit; from m_vasp_dc_368 import VaspPOSCAR; print('All imports successful')" || {
    echo "ERROR: Python import test failed!"
    exit 1
}
echo "=============================="

if [ -f .tmp ]; then
	rm .tmp
fi

if [ -f output_E ]; then
	rm output_E
fi

if [ ! -d structures ]; then
	mkdir structures
fi

if [ ! -d vac_structures ]; then
	mkdir vac_structures
fi

# rm structures/* ## BE CAREFUL

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
	$py $SRC_DIR/sc4.py >> $FNLOG 

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
	$py $SRC_DIR/sc2.py $i >> $FNLOG
done

# ============== rename _curr to _zero ==================
# Copy final structure for the next run
cp struct_curr.lmp   struct_zero.lmp
cp struct_curr_g.lmp struct_zero_g.lmp