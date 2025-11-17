#!/bin/bash
#PJM -g gn29
#PJM -L rscgrp=regular-o
#PJM -L elapse=00:10:00
#PJM -L node=1

cd $PJM_O_WORKDIR

echo "=== Setup Environment ==="
VENV_PATH="/work/02/gn29/n29001/MC_simulation/.venv"
SRC_DIR="/work/02/gn29/n29001/MC_simulation/src"
MODULE_DIR="/work/02/gn29/n29001/opt/modules"

# libpythonのパスを追加
export LD_LIBRARY_PATH="/usr/lib64:${LD_LIBRARY_PATH}"

source /etc/profile.d/modules.sh
module use /work/opt/local/modules/modulefiles/LN/odyssey/compiler

source ${VENV_PATH}/bin/activate
py="${VENV_PATH}/bin/python"

# システムのNumPyを使用
SYSTEM_NUMPY="/usr/lib64/python3.6/site-packages"
export PYTHONPATH="${SRC_DIR}:${MODULE_DIR}:${SYSTEM_NUMPY}:${PYTHONPATH}"

echo "Python: $py"
echo "PYTHONPATH: ${PYTHONPATH}"
echo "LD_LIBRARY_PATH: ${LD_LIBRARY_PATH}"

echo ""
echo "=== Test imports ==="
$py -c "import numpy; print('NumPy:', numpy.__version__)" 2>&1
$py -c "import sc2_unit; print('sc2_unit OK')" 2>&1
$py -c "import sc4_unit; print('sc4_unit OK')" 2>&1
$py -c "from m_vasp_dc_368 import VaspPOSCAR; print('VaspPOSCAR OK')" 2>&1

echo ""
echo "=== All together ==="
$py -c "import numpy; import sc2_unit; import sc4_unit; from m_vasp_dc_368 import VaspPOSCAR; print('ALL OK!')" 2>&1
