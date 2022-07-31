from setuptools import setup, Extension
from Cython.Build import cythonize

extensions = [
    Extension(
        name="lib",
        sources=["./ppm_gen.pyx"]),
    Extension(
        name="blob_blur_gif",
        sources=["./examples/blob_blur_gif.pyx"]
    )
]

setup(
    ext_modules  = cythonize(extensions, language_level=3),
)
