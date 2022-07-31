from lib import gen_image, to_jpeg
from PIL import Image

cdef struct Window:
    size_t width
    size_t height

cdef Window win
win.width  = 400
win.height = 400

cpdef main():
    cdef size_t i
    cdef unsigned char[:,:,:] image
    images = []

    for i in range(10):
        # gen image
        image = gen_image(win, i)

        # save to file
        file_name = f"./gifimages/output_{i}.jpeg"
        to_jpeg(image, win, file_name)
        
    for i in range(10):
        im = Image.open(f"./gifimages/output_{i}.jpeg")
        images.append(im)
    
    images[0].save("gifimages/output.gif", save_all=True, append_images=images, loop=0)
