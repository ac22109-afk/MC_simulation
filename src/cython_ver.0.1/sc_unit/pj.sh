#!/bin/bash
#PJM -g gn29
#PJM -L rscgrp=regular-o
#PJM -L elapse=00:10:00
#PJM -L node=1
#SBATCH --job-name=compile_cython
#SBATCH --output=compile_cython.log

# エラーが起きたら即停止
set -e

# ==========================================
# 1. ディレクトリとパスの設定 (pj.shと共通化)
# ==========================================
# ソースコードがあるディレクトリ
SRC_DIR="/work/02/gn29/n29001/MC_simulation/src/sc_unit"

# 仮想環境のパス
VENV_PATH="/work/02/gn29/n29001/MC_simulation/.venv"

# システムのNumPyパス (Wisteria標準のPython 3.6用)
# ここにある numpy/core/include を参照させるために必要です
SYSTEM_NUMPY_PATH="/usr/lib64/python3.6/site-packages"

# その他のモジュールパス
MODULE_DIR="/work/02/gn29/n29001/opt/modules"

echo "=== Environment Setup ==="
echo "Moving to SRC_DIR: $SRC_DIR"
cd "$SRC_DIR"

# ==========================================
# 2. 環境変数の設定 (pj.shと同じ構成)
# ==========================================
# 仮想環境をロード (Cython本体はここにある想定)
if [ -f "${VENV_PATH}/bin/activate" ]; then
    source "${VENV_PATH}/bin/activate"
    echo "Virtual environment activated."
else
    echo "ERROR: Virtual environment not found at ${VENV_PATH}"
    exit 1
fi

# ★最重要ポイント★
# pj.sh と同様に、システムのNumPyを PYTHONPATH に強制追加します。
# これにより setup.py 内の import numpy が成功し、includeパスが解決されます。
export PYTHONPATH="${SRC_DIR}:${MODULE_DIR}:${SYSTEM_NUMPY_PATH}:${PYTHONPATH}"

echo "PYTHONPATH configured: $PYTHONPATH"
echo "Using Python: $(which python)"

# 事前チェック: CythonとNumPyが見えているか確認
echo "--- Dependency Check ---"
python -c "import Cython; print(f'Cython ver: {Cython.__version__}')" || echo "WARNING: Cython not found!"
python -c "import numpy; print(f'NumPy path: {numpy.__file__}')" || echo "ERROR: NumPy not found!"

# ==========================================
# 3. コンパイル実行
# ==========================================
echo "=== Cleaning old builds ==="
# 前回のビルド失敗の残骸や、x86でビルドしてしまったファイルを消去
rm -rf build *.so *.c

echo "=== Running setup.py build_ext ==="
# --inplace: その場に .so ファイルを生成するオプション
python setup.py build_ext --inplace

echo "=== Verification ==="
# 出来上がった .so ファイルのアーキテクチャを確認 (AArch64なら成功)
ls -l *.so
readelf -h *.so | grep "Machine"

echo "Done."