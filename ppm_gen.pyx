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

cdef (unsigned char) blob_blur_mask(size_t row, size_t col, double factor):
    cdef double blob_radius_in  = min(WIDTH, HEIGHT) / 8
    cdef double blob_radius_out = blob_radius_in * 1.5 * factor
    cdef double dist_to_center  = dist_2d(col, row, WIDTH//2, HEIGHT//2)
    if dist_to_center < blob_radius_in:
        return 0
    else:
        return int(MAX_COLOR_VALUE * min(1, abs((dist_to_center - blob_radius_in) / (blob_radius_out - blob_radius_in))))


cdef (unsigned char) triangle_mask(size_t row, size_t col, size_t c):
    if col >= row:
        return 0
    else:
        return MAX_COLOR_VALUE

cdef (unsigned char) random_mask(size_t row, size_t col, size_t c):
    return randint(MIN_COLOR_VALUE, MAX_COLOR_VALUE)

# Image generation
# ================
cdef (unsigned char[:,:,:]) gen_image(size_t iter):
    cdef size_t row, col, c

    cyarr = cvarray(shape=(HEIGHT, WIDTH, N_CHANNELS), itemsize=sizeof(unsigned char), format="B")
    cdef unsigned char[:,:,:] image = cyarr

    for row in range(HEIGHT):
        for col in range(WIDTH):
            for c in range(N_CHANNELS):
                image[row, col, c] = blob_blur_mask(row, col, iter*0.4 + 1)

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

# Save image buffer to specific format
# ====================================
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
    cdef size_t i
    cdef unsigned char[:,:,:] image
    images = []

    for i in range(10):
        # gen image
        image = gen_image(i)

        # save to file
        file_name = f"./gifimages/output_{i}.jpeg"
        to_jpeg(image, file_name)
        
    for i in range(10):
        im = Image.open(f"./gifimages/output_{i}.jpeg")
        images.append(im)
    
    images[0].save("gifimages/output.gif", save_all=True, append_images=images, loop=0)