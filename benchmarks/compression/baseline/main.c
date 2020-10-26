#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <png.h>

typedef struct blob_t
{
    char* buffer;
    size_t count;
    size_t capacity;
} blob_t;


void blob_write(png_structp const context, png_bytep const data, png_size_t const count)
{
    blob_t* const blob = (blob_t*) png_get_io_ptr(context); 
    size_t const total = blob->count + count;
    if (total >= blob->capacity) 
    {
        while (blob->capacity < total) 
        {
            blob->capacity += (blob->capacity >> 1) + 16;
        }
        blob->buffer = realloc(blob->buffer, blob->capacity);
    }

    /* copy new bytes to end of buffer */
    memcpy(blob->buffer + blob->count, data, count);
    blob->count = total;
}

void
blob_flush(png_structp const context)
{
}

int main(int const count, char const* const* const arguments) 
{
    if (count != 4) 
    {
        printf("missing arguments\n");
        return -1;
    }
    int const z = arguments[3][0] - '0'; 
    if (arguments[3][1] != '\0' || z < 0 || z > 9) 
    {
        printf("compression level argument is not a single-digit integer\n");
    }
    
    FILE* source = fopen(arguments[1], "rb");
    if (!source)
    {
        printf("failed to open file\n");
        return -1;
    }
    
    png_structp png_in = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);

    if (!png_in) 
    {
        printf("failed to initialize libpng context\n");
        return -1;
    }
    png_infop info = png_create_info_struct(png_in);
    if (!info) 
    {
        png_destroy_read_struct(&png_in, NULL, NULL);
        return -1;
    }
    
    png_init_io(png_in, source);

    png_read_info(png_in, info);
    png_uint_32 width, height;
    int bit_depth, color_type, interlace_type; 
    png_get_IHDR(png_in, info, &width, &height, &bit_depth, &color_type,
        &interlace_type, NULL, NULL);
    png_read_update_info(png_in, info);
    png_color* palette_in;
    int palette_count;
    if (png_get_PLTE(png_in, info, &palette_in, &palette_count) != PNG_INFO_PLTE) 
    {
        palette_count = 0;
    }
    png_color palette_out[palette_count]; 
    for (int i = 0; i < palette_count; ++i) 
    {
        palette_out[i] = palette_in[i];
    }

    png_uint_32 const pitch = png_get_rowbytes(png_in, info);
    png_bytep const data    = png_malloc(png_in, height * pitch);
    
    png_bytep rows[height];
    for (png_uint_32 y = 0; y < height; ++y) 
    {
        rows[y] = data + y * pitch;
    }
    
    png_read_image(png_in, rows);
    png_read_end(png_in, info);
    
    png_destroy_read_struct(&png_in, &info, NULL);
    
    fclose(source);
    
    double const start = ((double) clock()) / CLOCKS_PER_SEC;
    
    png_structp png_out = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if (png_out == NULL)
    {
        return -1;
    }
    info = png_create_info_struct(png_out);
    if (!info) 
    {
        png_destroy_write_struct(&png_out, NULL);
        return -1;
    }
    
    //png_init_io(png_out, destination);
    blob_t blob = { .buffer = NULL, .count = 0 , .capacity = 0 };
    png_set_write_fn(png_out, &blob, blob_write, blob_flush);
    
    png_set_compression_level(png_out, z);
    png_set_IHDR(png_out, info, width, height, bit_depth, color_type,
        interlace_type, PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);
    if (palette_count > 0) 
    {
        png_set_PLTE(png_out, info, palette_out, palette_count);
    }
    png_set_rows(png_out, info, rows);
    png_write_png(png_out, info, PNG_TRANSFORM_IDENTITY, NULL);
    
    png_destroy_write_struct(&png_out, NULL);
    
    double const stop = ((double) clock()) / CLOCKS_PER_SEC;
    printf("%d %lf %lu %s\n", z, 1000.0 * (stop - start), blob.count, arguments[2]);
    
    free(blob.buffer);
    // FILE* destination = fopen(arguments[2], "wb");
    // if (!destination)
    // {
    //     printf("failed to open file\n");
    //     return -1;
    // }
    // fwrite(blob.buffer, 1, blob.count, destination);
    // fclose(destination);
    return 0;
}
