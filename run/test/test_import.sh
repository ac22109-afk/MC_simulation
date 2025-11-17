#!/bin/bash
#PJM -g gn29
#PJM -L rscgrp=regular-o
#PJM -L elapse=00:10:00
#PJM -L node=1

cd $PJM_O_WORKDIR

echo "=== Step 1: Environment Setup ==="
VENV_PATH="/work/02/gn29/n29001/MC_simulation/.venv"
SRC_DIR="/work/02/gn29/n29001/MC_simulation/src"
MODULE_DIR="/work/02/gn29/n29001/opt/modules"

source /etc/profile.d/modules.sh
module use /work/opt/local/modules/modulefiles/LN/odyssey/compiler

export PYTHONNOUSERSITE=0
source ${VENV_PATH}/bin/activate
py="${VENV_PATH}/bin/python"

echo "Python: $py"
$py --version

echo ""
echo "=== Step 2: Check .so files exist ==="
ls -la ${SRC_DIR}/*.so

echo ""
echo "=== Step 3: Test without PYTHONPATH ==="
$py -c "import sys; print('sys.path:'); print('\\n'.join(sys.path))"

echo ""
echo "=== Step 4: Test with SRC_DIR in PYTHONPATH ==="
export PYTHONPATH="${SRC_DIR}:${PYTHONPATH}"
echo "PYTHONPATH: ${PYTHONPATH}"
$py -c "import sys; print('sys.path:'); print('\\n'.join(sys.path))"

echo ""
echo "=== Step 5: Try importing sc2_unit ==="
$py -c "import sc2_unit; print('sc2_unit OK')" 2>&1 || echo "FAILED: sc2_unit"

echo ""
echo "=== Step 6: Try importing sc4_unit ==="
$py -c "import sc4_unit; print('sc4_unit OK')" 2>&1 || echo "FAILED: sc4_unit"

echo ""
echo "=== Step 7: Add MODULE_DIR and test VASP ==="
export PYTHONPATH="${SRC_DIR}:${MODULE_DIR}:${PYTHONPATH}"
echo "PYTHONPATH: ${PYTHONPATH}"
$py -c "from m_vasp_dc_368 import VaspPOSCAR; print('VaspPOSCAR OK')" 2>&1 || echo "FAILED: VaspPOSCAR"

echo ""
echo "=== Step 8: Test NumPy ==="
$py -c "import numpy; print('NumPy version:', numpy.__version__)" 2>&1 || echo "FAILED: NumPy"

echo ""
echo "=== Step 9: All imports together ==="
$py -c "import sc2_unit; import sc4_unit; from m_vasp_dc_368 import VaspPOSCAR; import numpy; print('ALL OK')" 2>&1 || echo "FAILED: Combined import"

echo ""
echo "=== Test Complete ==="
