#!/bin/bash
#PJM -g gn29
#PJM -L rscgrp=regular-o
#PJM -L elapse=00:10:00
#PJM -L node=1

echo "=== Check library dependencies ==="
ldd /work/02/gn29/n29001/MC_simulation/src/sc2_unit.so

echo ""
echo "=== Check if libpython is available ==="
ldconfig -p | grep libpython3.6m

echo ""
echo "=== LD_LIBRARY_PATH ==="
echo $LD_LIBRARY_PATH
