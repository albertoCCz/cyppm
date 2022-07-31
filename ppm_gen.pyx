from cython.view cimport array as cvarray
from libc.stdio cimport FILE, fopen, fclose, fputs, sprintf
from random import randint

from PIL import Image

cdef: 
    size_t N_CHANNELS = 3
    unsigned char MAX_COLOR_VALUE = 255
    unsigned char MIN_COLOR_VALUE = 0

cdef struct Window:
    size_t width
    size_t height


# Utility funtions
# ================
cdef fputs_header(Window win, FILE *f):
    header_str = bytes(f"P3\n{win.width} {win.height} {MAX_COLOR_VALUE}\n", 'UTF-8')
    cdef const char *header = header_str
    del header_str
    
    fputs(header, f)

cdef double dist_2d(size_t x1, size_t y1, size_t x2, size_t y2):
    return ((x1 - x2)**2 + (y1 - y2)**2)**(1/2)

# Masks
# =====
cpdef (unsigned char) blob_mask(Window win, size_t row, size_t col, size_t c):
    cdef double BLOB_RADIUS = win.width / 4 if win.width < win.height else win.height / 4
    if dist_2d(col, row, win.width//2, win.height//2) < BLOB_RADIUS:
        return 0
    else:
        return MAX_COLOR_VALUE

cpdef (unsigned char) blob_blur_mask(Window win, size_t row, size_t col, double factor):
    cdef double blob_radius_in  = min(win.width, win.height) / 8
    cdef double blob_radius_out = blob_radius_in * 1.5 * factor
    cdef double dist_to_center  = dist_2d(col, row, win.width//2, win.height//2)
    if dist_to_center < blob_radius_in:
        return 0
    else:
        return int(MAX_COLOR_VALUE * min(1, abs((dist_to_center - blob_radius_in) / (blob_radius_out - blob_radius_in))))


cpdef (unsigned char) triangle_mask(size_t row, size_t col, size_t c):
    if col >= row:
        return 0
    else:
        return MAX_COLOR_VALUE

cpdef (unsigned char) random_mask(size_t row, size_t col, size_t c):
    return randint(MIN_COLOR_VALUE, MAX_COLOR_VALUE)

# Image generation
# ================
cpdef (unsigned char[:,:,:]) gen_image(Window win, size_t iter):
    cdef size_t row, col, c

    cyarr = cvarray(shape=(win.height, win.width, N_CHANNELS), itemsize=sizeof(unsigned char), format="B")
    cdef unsigned char[:,:,:] image = cyarr

    for row in range(win.height):
        for col in range(win.width):
            for c in range(N_CHANNELS):
                image[row, col, c] = blob_blur_mask(win, row, col, iter*0.4 + 1)

    return image

# Dump generated image to file
# ============================
cdef void dump_image(unsigned char[:,:,:] image, Window win, FILE *f):
    cdef size_t row, col, c
    cdef char *channel_str = ""

    for row in range(win.height):
        for col in range(win.width):
            for c in range(N_CHANNELS):
                if c == 2:
                    sprintf(channel_str, "%d\t", image[row, col, c])
                    fputs(channel_str, f)
                else:
                    sprintf(channel_str, "%d ", image[row, col, c])
                    fputs(channel_str, f)

            if col == (win.width - 1): fputs("\n", f)

# Save image buffer to specific format
# ====================================
cpdef void to_ppm(unsigned char[:,:,:] image, Window win, char *file_name):
    # open the file
    cdef FILE *f = fopen(file_name, "w")

    # write the header
    fputs_header(win,f)

    # dump image to file
    dump_image(image, win, f)

    # close file
    fclose(f)

cpdef to_jpeg(unsigned char[:,:,:] image, Window win, file_name):
    # read from buffer
    image_jpeg = Image.frombuffer("RGB", (win.width, win.height), image, "raw", "RGB", 0, 1)

    # dump image to file
    image_jpeg.save(file_name)
