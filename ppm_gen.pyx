from cython.view cimport array as cvarray
from libc.stdio cimport FILE, fopen, fclose, fputs, sprintf
import array
from random import randint

cdef size_t WIDTH = 400
cdef size_t HEIGHT = 400
cdef size_t N_CHANNELS = 3
cdef size_t IMAGE_SIZE = WIDTH * HEIGHT * N_CHANNELS

cdef size_t MAX_COLOR_VALUE = 255
cdef size_t MIN_COLOR_VALUE = 0

# Utility funtions
# ================
cdef fputs_header(FILE *f):
    header_str = bytes(f"P3\n{WIDTH} {HEIGHT} {MAX_COLOR_VALUE}\n", 'UTF-8')
    cdef const char *header = header_str
    del header_str
    
    fputs(header, f)

cdef double dist_2d(size_t x1, size_t y1, size_t x2, size_t y2):
    return ((x1 - x2)**2 + (y1 - y2)**2)**(1/2)

# Masks
# =====
cdef (unsigned char) blob_mask(size_t row, size_t col, size_t c):
    cdef double BLOB_RADIUS = WIDTH / 4 if WIDTH < HEIGHT else HEIGHT / 4
    if dist_2d(col, row, WIDTH//2, HEIGHT//2) < BLOB_RADIUS:
        return 0
    else:
        return MAX_COLOR_VALUE

cdef (unsigned char) blob_blur_mask(size_t row, size_t col, size_t c):
    cdef double BLOB_RADIUS_IN  = WIDTH / 4 if WIDTH < HEIGHT else HEIGHT / 4
    cdef double BLOB_RADIUS_OUT = 1.5 * (WIDTH / 4) if WIDTH < HEIGHT else 1.5 * (HEIGHT / 4)
    cdef double dist_to_center  = dist_2d(col, row, WIDTH//2, HEIGHT//2)
    if dist_to_center < BLOB_RADIUS_IN:
        return 0
    else:
        return int(MAX_COLOR_VALUE * min(1, abs((dist_to_center - BLOB_RADIUS_IN) / (BLOB_RADIUS_OUT - BLOB_RADIUS_IN))))

cdef (unsigned char) triangle_mask(size_t row, size_t col, size_t c):
    if col >= row:
        return 0
    else:
        return MAX_COLOR_VALUE

cdef (unsigned char) random_mask(size_t row, size_t col, size_t c):
    return randint(MIN_COLOR_VALUE, MAX_COLOR_VALUE)

# Image generation
# ================
cdef (unsigned char[:,:,:]) gen_image():
    cdef size_t row, col, c

    cyarr = cvarray(shape=(HEIGHT, WIDTH, N_CHANNELS), itemsize=sizeof(unsigned char), format="B")
    cdef unsigned char[:,:,:] image = cyarr

    for row in range(HEIGHT):
        for col in range(WIDTH):
            for c in range(N_CHANNELS):
                image[row, col, c] = blob_blur_mask(row, col, c)

    return image

# Dump generated image to file
# ============================
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

# Run the thing
# =============
cpdef main():
    # open the file
    cdef const char *output_file_name = "output.ppm"
    cdef FILE *f = fopen(output_file_name, "w")

    # write the header
    fputs_header(f)

    # gen image
    cdef unsigned char[:,:,:] image = gen_image()

    # dump image to file
    dump_image(image, f)

    # close file
    fclose(f)
