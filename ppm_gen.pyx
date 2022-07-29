from cpython cimport array
from cython.view cimport array as cvarray
from libc.stdio cimport FILE, fopen, fclose, fputs, sprintf
import array
from random import randint

from PIL import Image

cdef size_t WIDTH = 400
cdef size_t HEIGHT = 400
cdef size_t N_CHANNELS = 3
cdef size_t IMAGE_SIZE = WIDTH * HEIGHT * N_CHANNELS

cdef unsigned char MAX_COLOR_VALUE = 255
cdef unsigned char MIN_COLOR_VALUE = 0

cdef fputs_header(FILE *f):
    header_str = bytes(f"P3\n{WIDTH} {HEIGHT} {MAX_COLOR_VALUE}\n", 'UTF-8')
    cdef const char *header = header_str
    del header_str
    
    fputs(header, f)

cdef (unsigned char) triangle_mask(size_t row, size_t col, size_t c):
    if col >= row:
        return 0
    else:
        return MAX_COLOR_VALUE

cdef (unsigned char) random_mask(size_t row, size_t col, size_t c):
    return randint(MIN_COLOR_VALUE, MAX_COLOR_VALUE)

cdef (unsigned char[:,:,:]) gen_image():
    cdef size_t row, col, c

    cyarr = cvarray(shape=(HEIGHT, WIDTH, N_CHANNELS), itemsize=sizeof(unsigned char), format="B")
    cdef unsigned char[:,:,:] image = cyarr

    for row in range(HEIGHT):
        for col in range(WIDTH):
            for c in range(N_CHANNELS):
                image[row, col, c] = random_mask(row, col, c)

    return image

cdef dump_image(unsigned char[:,:,:] image, FILE *f):
    cdef size_t row, col, c
    cdef char *channel_str = ""

    for row in range(HEIGHT):
        for col in range(WIDTH):
            for c in range(N_CHANNELS):
                if c == 2:
                    sprintf(channel_str, "%d\t", image[row, col, c])
                    fputs(channel_str, f)
                else:
                    sprintf(channel_str, "%d ", image[row, col, c])
                    fputs(channel_str, f)

            if col == (WIDTH - 1): fputs("\n", f)

cdef to_ppm(unsigned char[:,:,:] image, char *file_name):
    # open the file
    cdef FILE *f = fopen(file_name, "w")

    # write the header
    fputs_header(f)

    # dump image to file
    dump_image(image, f)

    # close file
    fclose(f)

cdef to_jpeg(unsigned char[:,:,:] image, file_name):
    # read from buffer
    image_jpeg = Image.frombuffer("RGB", (WIDTH, HEIGHT), image, "raw", "RGB", 0, 1)

    # dump image to file
    image_jpeg.save(file_name)

cpdef main():
    # gen image
    cdef unsigned char[:,:,:] image = gen_image()

    # save to file
    file_name = "output.jpeg"
    to_jpeg(image, file_name)
