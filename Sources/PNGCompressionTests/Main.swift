import PNG
import Testing

struct _TestFailure:Error
{
    let message:String
}

@main
enum Main:TestMain, TestBattery
{
    static
    func run(tests:TestGroup)
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
        for (name, members):(String, [String]) in suite
        {
            guard
            let tests:TestGroup = tests / name
            else
            {
                continue
            }

            for member:String in members
            {
                guard
                let tests:TestGroup = tests / member
                else
                {
                    continue
                }

                tests.do
                {
                    try Self.encode(member).get()
                }
            }
        }
    }

    static
    func encode(_ name:String) -> Result<Void, _TestFailure>
    {
        let path:(png:String, out:String) =
        (
            "Tests/Baselines/\(name).png",
            "Tests/Outputs/\(name).png"
        )

        do
        {
            guard let baseline:(image:PNG.Image, size:Int) =
                (try System.File.Source.open(path: path.png)
            {
                (try .decompress(stream: &$0), $0.count!)
            })
            else
            {
                return .failure(.init(message: "failed to open file '\(path.png)'"))
            }

            try baseline.image.compress(path: path.out, level: 9)

            guard let output:(image:PNG.Image, size:Int) =
                (try System.File.Source.open(path: path.out)
            {
                (try .decompress(stream: &$0), $0.count!)
            })
            else
            {
                return .failure(.init(message: "failed to open file '\(path.out)'"))
            }

            let pixels:[PNG.RGBA<UInt16>] = baseline.image.unpack(as: PNG.RGBA<UInt16>.self)
            print()
            print(name)
            print("baseline: \(baseline.size >> 10) KB, output: \(output.size >> 10) KB, ratio: \(Double.init(output.size) / Double.init(baseline.size))")

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
