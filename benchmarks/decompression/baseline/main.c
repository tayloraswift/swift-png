#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <png.h>

typedef struct blob_t
{
    char* buffer;
    size_t count;
    size_t capacity;
} blob_t;

int blob_load(blob_t* const blob, FILE* const source) 
{
    int const descriptor = fileno(source);
    if (descriptor == -1) 
    {
        return -1;
    }
    
    struct stat status;
    if (fstat(descriptor, &status) != 0) 
    {
        return -1;
    }
    
    switch (status.st_mode & S_IFMT) 
    {
    case S_IFREG: 
    case S_IFLNK:
        break; 
    default:
        return -1;
    }
    
    blob->capacity  = status.st_size;
    blob->count     = blob->capacity;
    blob->buffer    = malloc(blob->capacity);
    if (blob->buffer == NULL)
    {
        return -1;
    }
    if (fread(blob->buffer, 1, blob->capacity, source) != blob->capacity) 
    {
        free(blob->buffer);
        return -1;
    }
    
    return 0;
}
void blob_reload(blob_t* const blob) 
{
    blob->count = blob->capacity;
}

void blob_read(png_structp const context, png_bytep const data, png_size_t const count)
{
    blob_t* const blob = (blob_t*) png_get_io_ptr(context); 
    memcpy(data, blob->buffer + blob->capacity - blob->count, count);
    blob->count -= count;
}


void blob_release(blob_t* const blob) 
{
    free(blob->buffer);
    blob->buffer    = NULL;
    blob->count     = 0;
    blob->capacity  = 0;
}

int main(int const count, char const* const* const arguments) 
{
    if (count != 3) 
    {
        printf("usage: %s <image> <trials>\n", arguments[0]);
        return -1;
    }
    
    char* canary        = (char*) arguments[2];
    size_t const trials =  strtol(arguments[2], &canary, 10);
    
    if (canary == arguments[2])
    {
        printf("fatal error: '%s' is not a valid integer\n", arguments[2]);
        return -1;
    }
    
    FILE* source = fopen(arguments[1], "rb");
    if (!source)
    {
        printf("failed to open file\n");
        return -1;
    }
    
    
    blob_t blob;
    blob_load(&blob, source);
    fclose(source);
    
    for (size_t trial = 0; trial < trials; ++trial) 
    {
        // sleep for 0.1s between runs to emulate a “cold” start
        nanosleep((const struct timespec[]){{0, 100000000L}}, NULL);
        blob_reload(&blob);
        
        clock_t const start = clock();
        
        png_structp context = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);

        if (!context) 
        {
            printf("failed to initialize libpng context\n");
            return -1;
        }

        png_infop info = png_create_info_struct(context);
        if (!info) 
        {
            png_destroy_read_struct(&context, NULL, NULL);
            return -1;
        }
        
        png_set_read_fn(context, &blob, blob_read);

        png_read_info(context, info);
        png_uint_32 width, height;
        int bit_depth, color_type, interlace_type; 
        png_get_IHDR(context, info, &width, &height, &bit_depth, &color_type,
           &interlace_type, NULL, NULL);
        
        png_set_scale_16(context);
        if (color_type == PNG_COLOR_TYPE_PALETTE)
        {
            png_set_palette_to_rgb(context);
        }
        if (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8)
        {
            png_set_expand_gray_1_2_4_to_8(context);
        }
        if (png_get_valid(context, info, PNG_INFO_tRNS) != 0)
        {
            png_set_tRNS_to_alpha(context);
        }
        png_color_16* background;
        if (png_get_bKGD(context, info, &background) != 0)
        {
            png_set_background(context, background,
                PNG_BACKGROUND_GAMMA_FILE, 1, 1.0);
        }
        
        png_set_filler(context, 0xffff, PNG_FILLER_AFTER);
        png_read_update_info(context, info);

        png_uint_32 const pitch = png_get_rowbytes(context, info);
        png_bytep const data    = png_malloc(context, height * pitch);
        
        png_bytep rows[height];
        for (png_uint_32 y = 0; y < height; ++y) 
        {
            rows[y] = data + y * pitch;
        }
        
        png_read_image(context, rows);
        png_read_end(context, info);
        
        png_destroy_read_struct(&context, &info, NULL);
        
        clock_t const stop = clock();
        printf("%lf ", 1000.0 * ((double) (stop - start)) / CLOCKS_PER_SEC);
    }
    
    printf("\n");
    blob_release(&blob);
    return 0;
}
