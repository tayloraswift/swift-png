import MaxPNG

func test_decompose(path:String, log:inout [String]) -> Bool
{
    let (png_raw_data, png_properties):([UInt8], PNGProperties)
    do
    {
        (png_raw_data, png_properties) = try decode_png(path: path + ".png")
    }
    catch
    {
        log.append(String(describing: error))
        return false
    }

    guard let deinterlaced:[UInt8] = png_properties.deinterlace(raw_data: png_raw_data)
    else
    {
        log.append(String(describing: PNGReadError.InterlaceDimensionError))
        return false
    }

    var passing:Bool = true

    if !test_against_rgba64(png_data: deinterlaced, properties: png_properties.deinterlaced_properties, path_rgba: path + ".rgba", log: &log)
    {
        log.append("subtest deinterlace '\(path).png' failed")
        passing = false
    }

    do
    {
        try encode_png(path: path + "_deinterlace.png",
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
        let extended_name:String = path + "_\(i)"
        do
        {
            try encode_png(path: extended_name + ".png",
                           raw_data: sub_data,
                           properties: sub_properties)
        }
        catch
        {
            log.append(String(describing: error))
            passing = false
        }

        if !test_against_rgba64(png_data: sub_data, properties: sub_properties, path_rgba: extended_name + ".rgba", log: &log)
        {
            log.append("subtest decompose '\(path).png' (\(i + 1)/7) failed")
            passing = false
        }
    }

    return passing
}

func test_decompose(test_name:String, log:inout [String]) -> Bool
{
    return test_decompose(path: "Tests/\(test_name)", log: &log)
}
