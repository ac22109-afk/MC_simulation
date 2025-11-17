C:\\USERS\\AISLA\\PROGRAM\\SIMULATION\\MC\_SIMULATION

├─data

├─myenv\_MC

├─result

├─run

│  ├─caseA

│  │  │  pj.sh

│  │  │  struct\_zero.lmp

│  │  │  struct\_zero\_g.lmp

│  │  │

│  │  ├─curr\_step

│  │  │      :

│  │  └─results

│  └─template

│      │  pj.sh

│      │  struct\_zero.lmp

│      │  struct\_zero\_g.lmp

│      │

│      ├─curr\_step

│      │      .tmp

│      │      Al.10sw-10sw.ann

│      │      core.wo6112.1102617

│      │      IN.lammps

│      │      IN.minimize.lammps

│      │      Mg.10sw-10sw.ann

│      │      Si.10sw-10sw.ann

│      │

│      └─results

└─src

        sc2.py

        sc2\_unit.so

        sc4.py

        sc4\_unit.so

        \_\_init\_\_.py



\# (myenv) $ ← 仮想環境を有効化



\# case\_A の作業場所へ移動

cd experiments/case\_A/



\# 「src」パッケージの「simulation」モジュールを実行

\# (設定ファイルとして、今いる場所の config.ini を渡す)

python -m src.simulation --config config.ini --output results/

