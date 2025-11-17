#!/usr/bin/env python
# -*- coding: utf-8 -*-

# PYTHONPATH に /work/02/gn29/n29001/opt/modules/ が設定されている前提
from m_vasp_dc_368 import VaspPOSCAR
import numpy as np

# Cythonでコンパイルされたモジュールをインポート
# PYTHONPATH に src/ ディレクトリが設定されている前提
import sc4_unit

FN_CURR  = "struct_curr_g.lmp"
FN_NEW_G = "struct_new_g.lmp"
FN_NEW   = "curr_step/struct.lmp"

GHOST_TYPEID = "4"

R_IN = 3.0

N_GHOST = 1


## ---------------------------  MAIN --------------------------- ##

def main():
    vp = VaspPOSCAR.from_file(FN_CURR)

    # 構造を読み込み、スワップするペアを選択
    atom_pair = sc4_unit.read_struct_and_choose_pair(FN_CURR, GHOST_TYPEID, N_GHOST)

    print(f"Substitute atom[{atom_pair[0][0]}] of type[{atom_pair[0][1]}] with"+\
         f" atom[{atom_pair[1][0]}] of type[{atom_pair[1][1]}]")

    print(f"Atom [{atom_pair[1][0]}] z = {vp.arr_r[atom_pair[1][0]-1, 2]}")

    # ペアの原子タイプをスワップ
    sc4_unit.copy_and_swap_types(FN_CURR, FN_NEW_G, atom_pair, do_print=True)

    # 空孔を記録して除去
    sc4_unit.record_and_remove_vac(FN_NEW_G, FN_NEW, GHOST_TYPEID, N_GHOST)


## --------------------------- HOOK --------------------------- ##

if __name__ == '__main__':
    main()