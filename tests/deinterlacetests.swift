import PNG

func test_decompose(path_png:String, path_rgba:String, path_dest:String, log:inout [String]) -> Bool
{
    let (png_raw_data, png_properties):([UInt8], PNGProperties)
    do
    {
        (png_raw_data, png_properties) = try png_decode(path: path_png + ".png")
    }
    catch
    {
        log.append(String(describing: error))
        return false
    }

    guard let deinterlaced:[UInt8] = png_properties.deinterlace(raw_data: png_raw_data)
    else
    {
        log.append("InterlaceDimensionError")
        return false
    }

    var passing:Bool = true

    if !test_against_rgba64(png_data: deinterlaced, properties: png_properties.deinterlaced_properties, path_rgba: path_rgba + ".rgba", log: &log)
    {
        log.append("subtest deinterlace '\(path_png).png' failed")
        passing = false
    }

    do
    {
        try png_encode(path: path_dest + "_deinterlace.png",
                       raw_data: deinterlaced,
                       properties: png_properties.deinterlaced_properties)
    }
    catch
    {
        log.append(String(describing: error))
        return false
    }


    for (i, (sub_data, sub_properties)) in png_properties.decompose(raw_data: png_raw_data)!.enumerated()
    {
        do
        {
            try png_encode(path: path_dest + "_\(i).png",
                           raw_data: sub_data,
                           properties: sub_properties)
        }
        catch
        {
            log.append(String(describing: error))
            passing = false
        }

        if !test_against_rgba64(png_data: sub_data, properties: sub_properties, path_rgba: path_rgba + "_\(i).rgba", log: &log)
        {
            log.append("subtest decompose '\(path_png).png' (\(i + 1)/7) failed")
            passing = false
        }
    }

    return passing
}

func test_decompose(test_name:String, log:inout [String]) -> Bool
{
    return test_decompose(path_png: "tests/large/png/\(test_name)",
                          path_rgba: "tests/large/rgba/\(test_name)", path_dest: "tests/\(test_name)", log: &log)
}
