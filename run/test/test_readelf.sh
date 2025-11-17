#!/bin/bash
#PJM -g gn29
#PJM -L rscgrp=regular-o
#PJM -L elapse=00:10:00
#PJM -L node=1

echo "=== Architecture ==="
uname -m
uname -a

echo ""
echo "=== Check .so with readelf (doesn't need ldd) ==="
readelf -d /work/02/gn29/n29001/MC_simulation/src/sc2_unit.so | grep NEEDED

echo ""
echo "=== Check if required libraries exist ==="
ls -la /usr/lib64/libpython3.6m.so* 2>&1
ls -la /lib64/libpython3.6m.so* 2>&1

echo ""
echo "=== Try loading with explicit RPATH ==="
export LD_LIBRARY_PATH="/usr/lib64:/lib64:${LD_LIBRARY_PATH}"
echo "LD_LIBRARY_PATH: ${LD_LIBRARY_PATH}"

python3 << 'PYEOF'
import sys
import ctypes
import os

os.environ['LD_LIBRARY_PATH'] = '/usr/lib64:/lib64:' + os.environ.get('LD_LIBRARY_PATH', '')

try:
    # Try with RTLD_GLOBAL
    lib = ctypes.CDLL('/work/02/gn29/n29001/MC_simulation/src/sc2_unit.so', mode=ctypes.RTLD_GLOBAL)
    print('ctypes with RTLD_GLOBAL: OK')
except Exception as e:
    print(f'ctypes with RTLD_GLOBAL: FAILED - {e}')

try:
    # Try importing as Python module
    sys.path.insert(0, '/work/02/gn29/n29001/MC_simulation/src')
    import sc2_unit
    print('Python import: OK')
except Exception as e:
    print(f'Python import: FAILED - {e}')
PYEOF
