import PNG
import Testing

@Suite
enum Compression
{
    @Test(arguments: [
            "v8-monochrome-photographic",
            "v8-monochrome-nonphotographic",
            "v16-monochrome-photographic",
            "v16-monochrome-nonphotographic",
            "va8-monochrome-photographic",
            "va8-monochrome-nonphotographic",
            "va16-monochrome-photographic",
            "va16-monochrome-nonphotographic",
            "indexed8-monochrome-photographic",
            "indexed8-color-photographic",
            "indexed8-monochrome-nonphotographic",
            "indexed8-color-nonphotographic",
            "rgb8-monochrome-photographic",
            "rgb8-color-photographic",
            "rgb8-monochrome-nonphotographic",
            "rgb8-color-nonphotographic",
            "rgb16-monochrome-photographic",
            "rgb16-color-photographic",
            "rgb16-monochrome-nonphotographic",
            "rgb16-color-nonphotographic",
            "rgba8-monochrome-photographic",
            "rgba8-color-photographic",
            "rgba8-monochrome-nonphotographic",
            "rgba8-color-nonphotographic",
            "rgba16-monochrome-photographic",
            "rgba16-color-photographic",
            "rgba16-monochrome-nonphotographic",
            "rgba16-color-nonphotographic",
        ])
    static func Encode(_ name:String) throws
    {
        let path:(png:String, out:String) =
        (
            "Tests/Baselines/\(name).png",
            "Tests/Outputs/\(name).png"
        )

        guard let baseline:(image:PNG.Image, size:Int) =
            (try System.File.Source.open(path: path.png)
        {
            (try .decompress(stream: &$0), $0.count!)
        })
        else
        {
            Issue.record("failed to open file '\(path.png)'")
            return
        }

        try baseline.image.compress(path: path.out, level: 9)

        guard let output:(image:PNG.Image, size:Int) =
            (try System.File.Source.open(path: path.out)
        {
            (try .decompress(stream: &$0), $0.count!)
        })
        else
        {
            Issue.record("failed to open file '\(path.out)'")
            return
        }

        let pixels:[PNG.RGBA<UInt16>] = baseline.image.unpack(as: PNG.RGBA<UInt16>.self)

        print()
        print(name)
        print("""
            baseline: \(baseline.size >> 10) KB, \
            output: \(output.size >> 10) KB, \
            ratio: \(Double.init(output.size) / Double.init(baseline.size))
            """)

        for (i, pair):(Int, (PNG.RGBA<UInt16>, PNG.RGBA<UInt16>)) in
            zip(output.image.unpack(as: PNG.RGBA<UInt16>.self), pixels).enumerated()
        {
            #expect(pair.0 == pair.1, "mismatch in pixel \(i)")
        }
    }
}
