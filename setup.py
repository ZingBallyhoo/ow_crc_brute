from distutils.core import setup
from Cython.Build import cythonize
from distutils.extension import Extension

setup(
    ext_modules=cythonize(Extension("brute_crc32b", ["brute_crc32b.pyx", "crc2.c"])), requires=['Cython']
)
