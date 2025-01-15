import PNG
import Testing

@Suite
enum Premultiplication
{
    @Test
    static func VA8()
    {
        Self.test(
            color: UInt8.min ... UInt8.max,
            alpha: UInt8.min ... UInt8.max)
    }
    @Test
    static func VA16()
    {
        // exhaustive 16-bit premultiplication tests take way too long to run, so we
        // sample a select subset of the input space
        Self.test(
            color: (0 ..< 512).map{ _ in UInt16.random(in: .min ... .max) },
            alpha: (0 ..< 512).map{ _ in UInt16.random(in: .min ... .max) })
    }

    private
    static func test<T>(color:some Sequence<T>, alpha:some Sequence<T>)
        where T:FixedWidthInteger, T:UnsignedInteger
    {
        for color:T in color
        {
            for alpha:T in alpha
            {
                let direct:PNG.VA<T>        = .init(color, alpha),
                    premultiplied:PNG.VA<T> = direct.premultiplied

                let unquantized:Double  = (.init(alpha) * .init(color) / .init(T.max)),
                    quantized:T         = .init(unquantized.rounded())

                // the order is important here,, the short circuiting protects us from
                // overflow when `quantized` == 255
                #expect(premultiplied.v == quantized)

                let repremultiplied:PNG.VA<T> = premultiplied.straightened.premultiplied

                #expect(premultiplied == repremultiplied)
            }
        }
    }
}
