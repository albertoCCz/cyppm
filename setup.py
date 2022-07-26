from setuptools import setup
from Cython.Build import cythonize

setup(
    ext_modules  = cythonize("./ppm_gen.pyx", language_level=3),
)
