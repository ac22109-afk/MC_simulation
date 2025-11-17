#!/usr/bin/env python
# -*- coding: utf-8 -*-

from shutil import copyfile
from sys import argv

# Cythonでコンパイルされたモジュールをインポート
# PYTHONPATH に src/ ディレクトリが設定されている前提
import sc2_unit

FN_CURR = "data_curr_E"
FN_NEW = "data_new_E"
FN_OUT = "output_E"
ST_CURR_G = "struct_curr_g.lmp"
ST_NEW_G = "struct_new_g.lmp"
ST_OPT = "curr_step/struct_opt.lmp"
ST_CURR = "struct_curr.lmp"

T_Kelbin = 298


## ---------------------------  MAIN --------------------------- ##

def main():
    step_id = 0
    if len(argv) > 1:
        step_id = int(argv[1])

    # 最適化構造を保存
    copyfile(ST_OPT, f"structures/{step_id:05d}_struct.lmp")
    
    # Cython化された insert_ghosts を呼び出してゴーストを挿入
    sc2_unit.insert_ghosts(ST_OPT, ST_NEW_G, f"vac_structures/{step_id:05d}_struct_g.lmp")

    # Cython化された compare_energy を呼び出してエネルギー比較とMC判定
    acc = sc2_unit.compare_energy(T_Kelbin, FN_CURR, FN_NEW, FN_OUT, step_id)

    # 受理された場合、現在の構造を更新
    if acc:
        sc2_unit.insert_ghosts(ST_OPT, ST_NEW_G, ST_CURR_G)
        copyfile(ST_OPT, ST_CURR)


## --------------------------- HOOK --------------------------- ##

if __name__ == '__main__':
    main()