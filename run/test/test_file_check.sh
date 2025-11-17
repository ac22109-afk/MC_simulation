#!/bin/bash
#PJM -g gn29
#PJM -L rscgrp=regular-o
#PJM -L elapse=00:10:00
#PJM -L node=1

echo "=== File type check ==="
file /work/02/gn29/n29001/MC_simulation/src/sc2_unit.so

echo ""
echo "=== Try to load with Python ==="
python3 -c "
import sys
import ctypes
try:
    lib = ctypes.CDLL('/work/02/gn29/n29001/MC_simulation/src/sc2_unit.so')
    print('ctypes load: OK')
except Exception as e:
    print(f'ctypes load: FAILED - {e}')
"

echo ""
echo "=== Check file permissions and existence ==="
ls -la /work/02/gn29/n29001/MC_simulation/src/sc2_unit.so
stat /work/02/gn29/n29001/MC_simulation/src/sc2_unit.so

echo ""
echo "=== Check if it's a symlink ==="
readlink -f /work/02/gn29/n29001/MC_simulation/src/sc2_unit.so

echo ""
echo "=== Head of file (check if it's corrupted) ==="
head -c 100 /work/02/gn29/n29001/MC_simulation/src/sc2_unit.so | od -c | head -5
