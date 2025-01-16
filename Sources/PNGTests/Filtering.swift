#if DEBUG
@testable
import PNG
import Testing

@Suite
enum Filtering
{
    @Test(arguments: [1, 2, 3, 4, 5, 6, 7, 8])
    static func Delay(_ delay:Int)
    {
        let size:(x:Int, y:Int) = (24, 16)
        let original:[[UInt8]] = (0 ..< size.y).map
        {
            _ in [0] + (0 ..< size.x).map{ _ in UInt8.random(in: .min ... .max) }
        }

        let filtered:[[UInt8]] = .init(unsafeUninitializedCapacity: size.y)
        {
            $1 = $0.count
            guard
            let base:UnsafeMutablePointer<[UInt8]> = $0.baseAddress
            else
            {
                return
            }

            var last:[UInt8] = .init(repeating: 0, count: size.x + 1)
            for (i, line):(Int, [UInt8]) in zip($0.indices, original)
            {
                (base + i).initialize(to: PNG.Encoder.filter(line,
                    last: last,
                    delay: delay))
                last = line
            }
        }

        let unfiltered:[[UInt8]] = .init(unsafeUninitializedCapacity: size.y)
        {
            $1 = $0.count
            guard
            let base:UnsafeMutablePointer<[UInt8]> = $0.baseAddress
            else
            {
                return
            }

            var last:[UInt8] = .init(repeating: 0, count: size.x + 1)
            for (i, line):(Int, [UInt8]) in zip($0.indices, filtered)
            {
                var line:[UInt8] = line
                PNG.Decoder.defilter(&line, last: last, delay: delay)
                last  = line

                line[line.startIndex] = 0
                (base + i).initialize(to: line)
            }
        }

        for (a, b):([UInt8], [UInt8]) in zip(original, unfiltered)
        {
            #expect(a == b)
        }
    }
}
#endif
