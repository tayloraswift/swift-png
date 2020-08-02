import PNG4

extension Test 
{
    static 
    var cases:[(name:String, function:Function)] 
    {
        let suite:[(name:String, members:[String])] =
        [
            (
                "v8",
                [
                    "v8-monochrome-photographic",
                    "v8-monochrome-nonphotographic",
                ]
            ),
            (
                "v16",
                [
                    "v16-monochrome-photographic",
                    "v16-monochrome-nonphotographic",
                ]
            ),
            (
                "va8",
                [
                    "va8-monochrome-photographic",
                    "va8-monochrome-nonphotographic",
                ]
            ),
            (
                "va16",
                [
                    "va16-monochrome-photographic",
                    "va16-monochrome-nonphotographic",
                ]
            ),
            (
                "indexed8",
                [
                    "indexed8-monochrome-photographic",
                    "indexed8-color-photographic",
                    "indexed8-monochrome-nonphotographic",
                    "indexed8-color-nonphotographic",
                ]
            ),
            (
                "rgb8",
                [
                    "rgb8-monochrome-photographic",
                    "rgb8-color-photographic",
                    "rgb8-monochrome-nonphotographic",
                    "rgb8-color-nonphotographic",
                ]
            ),
            (
                "rgb16",
                [
                    "rgb16-monochrome-photographic",
                    "rgb16-color-photographic",
                    "rgb16-monochrome-nonphotographic",
                    "rgb16-color-nonphotographic",
                ]
            ),
            (
                "rgba8",
                [
                    "rgba8-monochrome-photographic",
                    "rgba8-color-photographic",
                    "rgba8-monochrome-nonphotographic",
                    "rgba8-color-nonphotographic",
                ]
            ),
            (
                "rgba16",
                [
                    "rgba16-monochrome-photographic",
                    "rgba16-color-photographic",
                    "rgba16-monochrome-nonphotographic",
                    "rgba16-color-nonphotographic",
                ]
            ),
        ]
        
        return suite.map 
        {
            ($0.name, .string(Self.encode(_:), $0.members))
        }
    }
    private static 
    func print(image rgb:[PNG.RGBA<UInt16>], size:(x:Int, y:Int)) 
    {
        let downsample:Int = min(max(1, size.x / 16), max(1, size.y / 16))
        for i:Int in stride(from: 0, to: size.y, by: downsample)
        {
            let line:String = stride(from: 0, to: size.x, by: downsample).map 
            {
                (j:Int) in 
                
                // downsampling 
                var r:Int = 0, 
                    g:Int = 0, 
                    b:Int = 0 
                for y:Int in i ..< min(i + downsample, size.y) 
                {
                    for x:Int in j ..< min(j + downsample, size.x)
                    {
                        let c:PNG.RGBA<UInt16> = rgb[x + y * size.x]
                        r += .init(c.r)
                        g += .init(c.g)
                        b += .init(c.b)
                    }
                }
                
                let count:Int = 
                    (min(i + downsample, size.y) - i) * 
                    (min(j + downsample, size.x) - j)
                let c:(r:Float, g:Float, b:Float) = 
                (
                    .init(r) / (65535 * .init(count)),
                    .init(g) / (65535 * .init(count)),
                    .init(b) / (65535 * .init(count))
                )
                return Highlight.square(c)
            }.joined(separator: "")
            Swift.print(line)
        } 
    }
    
    static 
    func encode(_ name:String) -> Result<Void, Failure>
    {
        let path:(png:String, out:String) = 
        (
            "tests/compression/baseline/\(name).png",
            "tests/compression/out/\(name).png"
        )

        do
        {
            guard let baseline:(image:PNG.Data.Rectangular, size:Int) = 
                (try System.File.Source.open(path: path.png) 
            {
                (try .decompress(stream: &$0), $0.count!)
            })
            else
            {
                return .failure(.init(message: "failed to open file '\(path.png)'"))
            }
            
            try baseline.image.compress(path: path.out, level: 9)
            
            guard let output:(image:PNG.Data.Rectangular, size:Int) = 
                (try System.File.Source.open(path: path.out) 
            {
                (try .decompress(stream: &$0), $0.count!)
            })
            else
            {
                return .failure(.init(message: "failed to open file '\(path.out)'"))
            }
            
            let pixels:[PNG.RGBA<UInt16>] = baseline.image.unpack(as: PNG.RGBA<UInt16>.self)
            let filesize:(baseline:Double, output:Double) = 
            (
                .init(baseline.size),
                .init(output.size)
            )
            Swift.print()
            Swift.print(name)
            //Self.print(image: pixels, size: baseline.image.size)
            Swift.print("baseline: \(String.init(filesize.baseline / 1024.0, places: 4)) KB, output: \(String.init(filesize.output / 1024.0, places: 4)) KB, ratio: \(String.init(filesize.output / filesize.baseline, places: 4))")

            for (i, pair):(Int, (PNG.RGBA<UInt16>, PNG.RGBA<UInt16>)) in
                zip(output.image.unpack(as: PNG.RGBA<UInt16>.self), pixels).enumerated()
            {
                guard pair.0 == pair.1
                else
                {
                    return .failure(.init(message: "pixel \(i) has value \(pair.0) (expected \(pair.1))"))
                }
            }

            return .success(())
        }
        catch
        {
            return .failure(.init(message: "\(error)"))
        }
    } 
}
