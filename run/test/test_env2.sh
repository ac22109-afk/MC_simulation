#!/bin/bash
#PJM -g gn29
#PJM -L rscgrp=regular-o
#PJM -L elapse=00:10:00
#PJM -L node=1

cd $PJM_O_WORKDIR

VENV_PATH="/work/02/gn29/n29001/MC_simulation/.venv"
source ${VENV_PATH}/bin/activate
py="${VENV_PATH}/bin/python"

echo "=== Environment Check ==="
echo "which python: $(which python)"
$py --version

echo "=== Testing NumPy ==="
$py -c "import numpy; print('NumPy:', numpy.__version__)" 2>&1 || echo "NumPy import FAILED"

echo "=== Testing Cython modules ==="
export PYTHONPATH="/work/02/gn29/n29001/MC_simulation/src:${PYTHONPATH}"
$py -c "import sc2_unit; print('sc2_unit OK')" 2>&1 || echo "sc2_unit import FAILED"
$py -c "import sc4_unit; print('sc4_unit OK')" 2>&1 || echo "sc4_unit import FAILED"

echo "=== Testing VASP module ==="
export PYTHONPATH="/work/02/gn29/n29001/MC_simulation/src:/work/02/gn29/n29001/opt/modules:${PYTHONPATH}"
$py -c "from m_vasp_dc_368 import VaspPOSCAR; print('VaspPOSCAR OK')" 2>&1 || echo "VaspPOSCAR import FAILED"

echo "=== All Done ==="
