@testable import PNG
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
        if  let tests:TestGroup = tests / "Filtering"
        {
            for count:Int in [1, 2, 3, 4, 5, 6, 7, 8]
            {
                guard
                let tests:TestGroup = tests / "\(count)"
                else
                {
                    continue
                }

                tests.do { try Self.filtering(delay: count).get() }
            }
        }
        if  let tests:TestGroup = tests / "Premultiplication"
        {
            if  let tests:TestGroup = tests / "UInt8"
            {
                tests.do { try Self.premultiplication8().get() }
            }
            if  let tests:TestGroup = tests / "UInt16"
            {
                tests.do { try Self.premultiplication16().get() }
            }
        }
    }
}
extension Main
{
    static
    func filtering(delay:Int) -> Result<Void, _TestFailure>
    {
        let size:(x:Int, y:Int) = (24, 16)
        let original:[[UInt8]] = (0 ..< size.y).map
        {
            _ in [0] + (0 ..< size.x).map{ _ in UInt8.random(in: .min ... .max) }
        }

        let filtered:[[UInt8]] = .init(unsafeUninitializedCapacity: size.y)
        {
            $1 = $0.count
            guard let base:UnsafeMutablePointer<[UInt8]> = $0.baseAddress
            else
            {
                return
            }

            var last:[UInt8] = .init(repeating: 0, count: size.x + 1)
            for (i, line):(Int, [UInt8]) in zip($0.indices, original)
            {
                (base + i).initialize(to: PNG.Encoder.filter(line, last: last, delay: delay))
                last = line
            }
        }

        let unfiltered:[[UInt8]] = .init(unsafeUninitializedCapacity: size.y)
        {
            $1 = $0.count
            guard let base:UnsafeMutablePointer<[UInt8]> = $0.baseAddress
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
            guard a == b
            else
            {
                return .failure(.init(message: "original and filter-cycled scanlines do not match"))
            }
        }
        return .success(())
    }

    static
    func premultiplication8() -> Result<Void, _TestFailure>
    {
        Self.premultiplication(for: UInt8.self, over: (.min ... .max, .min ... .max))
    }
    // exhaustive 16-bit premultiplication tests take way too long to run, so we
    // sample a select subset of the input space
    static
    func premultiplication16() -> Result<Void, _TestFailure>
    {
        Self.premultiplication(for: UInt16.self, over:
        (
            (0 ..< 512).map{ _ in .random(in: .min ... .max) },
            (0 ..< 512).map{ _ in .random(in: .min ... .max) }
        ))
    }
    static
    func premultiplication<T, C>(for _:T.Type, over:(color:C, alpha:C)) -> Result<Void, _TestFailure>
        where   T:FixedWidthInteger & UnsignedInteger,
                C:Collection, C.Element == T
    {
        for color:T in over.color
        {
            for alpha:T in over.alpha
            {
                let direct:PNG.VA<T>        = .init(color, alpha),
                    premultiplied:PNG.VA<T> = direct.premultiplied

                let unquantized:Double  = (.init(alpha) * .init(color) / .init(T.max)),
                    quantized:T         = .init(unquantized.rounded())

                // the order is important here,, the short circuiting protects us from
                // overflow when `quantized` == 255
                guard premultiplied.v == quantized
                else
                {
                    return .failure(.init(message: "premultiplication of va\(T.bitWidth)(\(direct.v), \(direct.a)) returned (\(premultiplied.v), \(premultiplied.a)), expected (\(unquantized), \(alpha))"))
                }

                let repremultiplied:PNG.VA<T> = premultiplied.straightened.premultiplied
                guard premultiplied == repremultiplied
                else
                {
                    return .failure(.init(message: "premultiplication of va\(T.bitWidth)(\(direct.v), \(direct.a)) failed to round-trip correctly"))
                }
            }
        }

        return .success(())
    }
}
