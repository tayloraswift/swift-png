import MaxPNG

func test_decompose_and_deinterlace(relative_path:String, index:Int) -> Bool
{
    let (png_raw_data, png_header):([UInt8], PNGHeader)
    do
    {
        (png_raw_data, png_header) = try decode_png(relative_path: relative_path + ".png")
    }
    catch
    {
        print(error)
        return false
    }

    guard let deinterlaced:[UInt8] = png_header.deinterlace(raw_data: png_raw_data)
    else
    {
        print(PNGReadError.InterlaceDimensionError)
        return false
    }

    var passing:Bool = true

    if test_against_rgba64(png_data: deinterlaced, header: png_header.deinterlaced_header, relative_path_rgba: relative_path + ".rgba")
    {
        print("\(green_bold)(deinterlace:\(index)) test '\(relative_path).png' passed\(color_off)")
    }
    else
    {
        print("\(red_bold  )(deinterlace:\(index)) test '\(relative_path).png' failed\(color_off)")
        passing = false
    }

    do
    {
        try encode_png(relative_path: relative_path + "_deinterlace.png",
                       raw_data: deinterlaced,
                       header: png_header.deinterlaced_header)
    }
    catch
    {
        print(error)
        return false
    }


    for (i, (sub_data, sub_header)) in png_header.decompose(raw_data: png_raw_data)!.enumerated()
    {
        let extended_name:String = relative_path + "_deinterlace_\(i)"
        do
        {
            try encode_png(relative_path: extended_name + ".png",
                           raw_data: sub_data,
                           header: sub_header)
        }
        catch
        {
            print(error)
            passing = false
        }

        if test_against_rgba64(png_data: sub_data, header: sub_header, relative_path_rgba: extended_name + ".rgba")
        {
            print("\(green_bold)(decompose:\(index):\(i)) test '\(extended_name).png' passed\(color_off)")
        }
        else
        {
            print("\(red_bold  )(decompose:\(index):\(i)) test '\(extended_name).png' failed\(color_off)")
            passing = false
        }
    }

    return passing
}
