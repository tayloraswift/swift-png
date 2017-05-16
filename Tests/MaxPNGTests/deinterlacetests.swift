import MaxPNG

func test_decompose_and_deinterlace(path:String, index:Int) -> Bool
{
    let (png_raw_data, png_header):([UInt8], PNGHeader)
    do
    {
        (png_raw_data, png_header) = try decode_png(path: path + ".png")
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

    if test_against_rgba64(png_data: deinterlaced, header: png_header.deinterlaced_header, path_rgba: path + ".rgba")
    {
        print("\(green_bold)(deinterlace:\(index)) test '\(path).png' passed\(color_off)")
    }
    else
    {
        print("\(red_bold  )(deinterlace:\(index)) test '\(path).png' failed\(color_off)")
        passing = false
    }

    do
    {
        try encode_png(path: path + "_deinterlace.png",
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
        let extended_name:String = path + "_deinterlace_\(i)"
        do
        {
            try encode_png(path: extended_name + ".png",
                           raw_data: sub_data,
                           header: sub_header)
        }
        catch
        {
            print(error)
            passing = false
        }

        if test_against_rgba64(png_data: sub_data, header: sub_header, path_rgba: extended_name + ".rgba")
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
