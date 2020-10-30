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

void blob_create(blob_t* const blob)
{
    blob->buffer    = NULL;
    blob->count     = 0;
    blob->capacity  = 0;
}

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

void blob_flush(png_structp const context)
{
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
    if (count != 4) 
    {
        printf("usage: %s <compression-level:0 ... 9> <image> <trials>\n", arguments[0]);
        return -1;
    }
    
    char* canary        = (char*) arguments[1];
    size_t const z      =  strtol(arguments[1], &canary, 10);
    
    if (canary == arguments[1] || z < 0 || z > 9)
    {
        printf("fatal error: '%s' is not a valid integer from 0 to 9\n", arguments[1]);
        return -1;
    }
    
    canary              = (char*) arguments[3];
    size_t const trials =  strtol(arguments[3], &canary, 10);
    
    if (canary == arguments[3])
    {
        printf("fatal error: '%s' is not a valid integer\n", arguments[3]);
        return -1;
    }
    
    FILE* source = fopen(arguments[2], "rb");
    if (!source)
    {
        printf("failed to open file '%s'\n", arguments[2]);
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
    
    for (size_t trial = 0; trial < trials; ++trial) 
    {
        // sleep for 0.1s between runs to emulate a “cold” start
        nanosleep((const struct timespec[]){{0, 100000000L}}, NULL);
        clock_t const start = clock();
        
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
        
        blob_t blob;
        blob_create(&blob);
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
        
        clock_t const stop = clock();
        
        printf("%lf", 1000.0 * ((double) (stop - start)) / CLOCKS_PER_SEC);
        if (trial == trials - 1)
        {
            printf(", %lu ", blob.count);
        }
        else 
        {
            printf(" ");
        }
        
        blob_release(&blob);
    }
    
    printf("\n");
    
    return 0;
}
