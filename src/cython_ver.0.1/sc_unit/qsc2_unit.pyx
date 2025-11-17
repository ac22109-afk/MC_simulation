# distutils: define_macros=NPY_NO_DEPRECATED_API=NPY_1_7_API_VERSION
# cython: language_level=3

"""
qsc2_unit.pyx - エネルギー比較とゴーストアトム挿入のためのCythonモジュール

Functions:
    read_energy: エネルギーファイルから現在と新規のエネルギーを読み込む (内部用)
    compare_energy: エネルギーを比較してモンテカルロ判定を行う
    insert_ghosts: 構造ファイルにゴーストアトムを挿入する
"""

from math import exp
from random import random

# この関数は compare_energy からのみ呼ばれるため、
# C レベル専用の cdef 関数とし、タプルを返すようにする
cdef tuple read_energy(str fn, str fn_new):
    """
    エネルギーファイルから現在と新規のエネルギー値を読み込む
    
    Args:
        fn: 現在のエネルギーファイルパス
        fn_new: 新規のエネルギーファイルパス
    
    Returns:
        tuple: (現在のエネルギー, 新規のエネルギー)
    """
    cdef float curr_E=0.0
    cdef float new_E=0.0
    
    # 現在のエネルギーを読み込む
    with open(fn, 'r') as curr:
        curr.readline()  # ヘッダー行をスキップ
        cl1 = curr.readline()
        cl1_list = cl1.split()
        curr_E = float(cl1_list[2])
    
    print(f"current_E = {curr_E:12.7f}")

    # 新規のエネルギーを読み込む
    with open(fn_new, 'r') as new:
        new.readline()  # ヘッダー行をスキップ
        cl2 = new.readline()
        cl2_list = cl2.split()
        new_E = float(cl2_list[2])
    
    print(f"new_E = {new_E:12.7f}")
    
    return curr_E, new_E


cpdef bint compare_energy(int T, str fn_curr, str fn_new, str fn_out, int step_id):
    """
    モンテカルロ法によるエネルギー比較と受理判定
    
    Args:
        T: 温度 (Kelvin)
        fn_curr: 現在のエネルギーファイルパス
        fn_new: 新規のエネルギーファイルパス
        fn_out: 出力ファイルパス
        step_id: ステップID
    
    Returns:
        bool: 受理された場合True、棄却された場合False
    """
    # cdef 関数をCレベルで高速に呼び出す
    cdef float curr_E, new_E
    curr_E, new_E = read_energy(fn_curr, fn_new)

    # ボルツマン定数 (eV/K)
    cdef double k = 8.617333262e-5
    cdef float dE = new_E - curr_E
    cdef float argument = (-1.0) * dE / (k * T)
    cdef bint acc = False
    cdef float boltman, r

    # メトロポリス判定
    if argument > 0:
        # エネルギーが下がった場合は必ず受理
        acc = True
    else:
        # エネルギーが上がった場合は確率的に受理
        print("Calculate probability")
        boltman = exp(argument)
        r = random()
        print(f" dE = {dE:12.7f}  boltman = {boltman:8.6f} r = {r:8.6f}")
        acc = (boltman > r)

    # 結果を出力ファイルに書き込む
    with open(fn_out, 'a') as out_E:
        if acc:
            print("+" * 20 + " accepted")
            curr_E = new_E
            # 現在のエネルギーファイルを更新
            with open(fn_curr, 'w') as currf:
                currf.write("# current E\n")
                currf.write(f" optimized E  {curr_E} \n")
            out_E.write(f" {step_id:5d}  {new_E:15.7f}  accepted\n")
        else:
            print("-" * 20 + "rejected")
            out_E.write(f" {step_id:5d}  {new_E:15.7f}  rejected\n")

    return acc


cpdef void insert_ghosts(str st_opt, str st_new_g, str st_curr_g):
    """
    構造ファイルにゴーストアトムを挿入する
    
    Args:
        st_opt: 最適化された構造ファイルパス
        st_new_g: ゴーストアトムを含む新規構造ファイルパス
        st_curr_g: ゴーストアトムを挿入する出力ファイルパス
    """
    cdef int n_ghost = 0
    cdef list ghost = []
    cdef list ghost_ID = []
    cdef list vlo_ghost = []

    # ゴーストアトムの情報を読み込む
    with open(st_new_g, 'r') as info:
        while True:
            cl4 = info.readline()
            if cl4 == "":
                break
            cl4_list = cl4.split()
            # タイプ4のアトム（ゴースト）を検出
            if (len(cl4_list) > 4) and (cl4_list[1] == "4"):
                ghost.append(cl4.rstrip("\n"))
                n_ghost += 1
                ghost_ID.append(cl4_list[0])
            # ゴーストアトムの速度情報
            if (2 < len(cl4_list) < 5) and (cl4_list[0] in ghost_ID):
                vlo_ghost.append(cl4.rstrip("\n"))

    # 出力ファイルを作成
    cdef bint in_masses_section = False
    cdef int nAtoms, nType, ig
    
    with open(st_curr_g, 'w') as curr_g, open(st_opt, 'r') as opt:
        while True:
            cl3 = opt.readline()
            if cl3 == "":
                break

            # Massesセクションの検出
            if "Masses" in cl3:
                in_masses_section = True
            
            if "Atoms" in cl3:
                in_masses_section = False

            # アトム数を更新（ゴーストを追加）
            if "atoms" in cl3:
                nAtoms = int(cl3.split()[0])
                cl3 = f"{nAtoms + n_ghost} atoms\n"
            
            # アトムタイプ数を更新
            if "atom types" in cl3:
                nType = int(cl3.split()[0])
                cl3 = f"{nType + 1} atom types\n"
            
            # Massesセクションにゴーストタイプの質量を追加
            if in_masses_section and cl3.strip().startswith("3 28.09"):
                cl3 = "3 28.09\n4 10.00\n"

            # Atomsセクションにゴーストアトムを挿入
            if "Atoms # atomic" in cl3:
                opt.readline()  # 空行をスキップ
                cl3 = "Atoms # atomic\n\n"
                for ig in range(n_ghost):
                    cl3 += ghost[ig] + "\n"
            
            # Velocitiesセクションにゴースト速度を挿入
            if "Velocities" in cl3:
                opt.readline()  # 空行をスキップ
                cl3 = "Velocities\n\n"
                for ig in range(n_ghost):
                    cl3 += vlo_ghost[ig] + "\n"
            
            curr_g.write(cl3)