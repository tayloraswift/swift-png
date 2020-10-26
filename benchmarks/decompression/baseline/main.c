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
    if (count < 2) 
    {
        printf("missing file path arguments");
        return -1;
    }
    
    FILE* source = fopen(arguments[1], "rb");
    if (!source)
    {
        printf("failed to open file\n");
        return -1;
    }
    
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
    
    blob_t blob;
    blob_load(&blob, source);
    
    double const start = ((double) clock()) / CLOCKS_PER_SEC;
    
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
    
    double const stop = ((double) clock()) / CLOCKS_PER_SEC;
    printf("%lf %lu %s\n", 1000.0 * (stop - start), blob.capacity, arguments[2]);
    
    fclose(source);
    blob_release(&blob);
    
    // FILE* destination = fopen(arguments[2], "wb");
    // if (!destination)
    // {
    //     printf("failed to open file\n");
    //     return -1;
    // }
    // 
    // fwrite(data, 1, height * pitch, destination);
    // fclose(destination);
    
    return 0;
}
