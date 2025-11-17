#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
setup.py for building Cython extensions

Usage:
    python setup.py build_ext --inplace
"""

from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize
import numpy

# Define extensions
extensions = [
    Extension(
        "sc2_unit",
        ["sc2_unit.pyx"],
        include_dirs=[numpy.get_include()],
        extra_compile_args=['-O3'],
    ),
    Extension(
        "sc4_unit",
        ["sc4_unit.pyx"],
        include_dirs=[numpy.get_include()],
        extra_compile_args=['-O3'],
    ),
]

setup(
    name='MC_Cython_Modules',
    ext_modules=cythonize(
        extensions,
        compiler_directives={
            'language_level': '3',
            'boundscheck': False,
            'wraparound': False,
        }
    ),
    include_dirs=[numpy.get_include()],
)