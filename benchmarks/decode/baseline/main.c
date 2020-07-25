#include <stdio.h>
#include <png.h>

int main(int const count, char const* const* const arguments) 
{
    if (count < 3) 
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
    
    png_init_io(context, source);

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
    
    fclose(source);
    
    FILE* destination = fopen(arguments[2], "wb");
    if (!destination)
    {
        printf("failed to open file\n");
        return -1;
    }
    
    fwrite(data, 1, height * pitch, destination);
    fclose(destination);
    
    return 0;
}
