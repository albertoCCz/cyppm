# cyppm
This repo is just for me to play with Cython and try to learn something.

## Quickstart
Clone the repo and install the requirements:
```cmd
git clone https://github.com/albertoCCz/cyppm.git
cd cyppm
python -m venv env
source /env/bin/activate

python -m pip install -r requirements.txt
```
Build the `ppm_gen` module for your platform and Python version (Python 3.x version is the target, as specified in the `setup.py` file) with:
```cmd
python setup.py build_ext --inplace
rm *.c
```

## Usage
You can generate a `.ppm` image by calling the `main` function:
```cmd
$ python
...
>>> from ppm_gen import main
>>> main()
```
which generates an `output.ppm` image file that can be visualized [here](https://www.cs.rhodes.edu/welshc/COMP141_F16/ppmReader.html).

At this moment, masks `random_mask` and `triangle_mask` can be used to generate images. The result of using each one is the next:
<p align="middle">
    <img src="images/random.jpg" width="200" />
    <img src="images/triangle.jpg" width="200" />
</p>

(The images have been converted to `.jpg` for the porpuse of visualizing them here)