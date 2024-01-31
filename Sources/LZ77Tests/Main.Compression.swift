import LZ77
import Testing

extension Main
{
    enum Compression
    {
    }
}
extension Main.Compression:TestBattery
{
    static
    func run(tests:TestGroup)
    {
        for (level, name):(Int, String) in
        [
            (4, "Greedy"),
            (7, "Lazy"),
            (9, "Full"),
        ]
        {
            guard
            let tests:TestGroup = tests / name
            else
            {
                continue
            }
            for count:Int in [5, 15, 100, 200, 2000, 5000]
            {
                guard
                let tests:TestGroup = tests / "\(count)"
                else
                {
                    continue
                }

                tests.do
                {
                    let input:[UInt8] = (0 ..< count).map{ _ in .random(in: .min ... .max) }

                    var deflator:LZ77.Deflator = .init(level: level, exponent: 8, hint: 16)
                        deflator.push(input[...], last: true)

                    var compressed:[UInt8] = []
                    while let part:[UInt8] = deflator.pull()
                    {
                        compressed += part
                    }

                    var inflator:LZ77.Inflator = .init()
                    try inflator.push(compressed[...])

                    let output:[UInt8] = inflator.pull()

                    tests.expect(input ..? output)
                }
            }
        }
    }
}
