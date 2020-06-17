@testable import PNG

extension Test 
{
    static 
    var cases:[(name:String, function:Function)] 
    {
        [
            ("premultiplication (8-bit)",   .void(Self.premultiplication8)),
            // ("premultiplication (16-bit)", .void(Self.premultiplication16)),
        ]
    }
    
    static 
    func premultiplication8() -> Result<Void, Failure>
    {
        Self.premultiplication(for: UInt8.self)
    }
    // 16-bit premultiplication tests take way too long to run
    // static 
    // func premultiplication16() -> Result<Void, Failure>
    // {
    //     Self.premultiplication(for: UInt16.self)
    // }
    static 
    func premultiplication<Sample>(for _:Sample.Type) -> Result<Void, Failure>
        where Sample:FixedWidthInteger & UnsignedInteger
    {
        for alpha:Sample in Sample.min ... Sample.max
        {
            for color:Sample in Sample.min ... Sample.max
            {
                let direct:PNG.RGBA<Sample>        = .init(color, alpha),
                    premultiplied:PNG.RGBA<Sample> = direct.premultiplied

                let unquantized:Double = (Double(alpha) * Double(color) / Double(Sample.max)),
                    quantized:Sample   = .init(unquantized)

                // the order is important here,, the short circuiting protects us from
                // overflow when `quantized` == 255
                guard premultiplied.r == quantized || premultiplied.r == quantized + 1
                else
                {
                    return .failure(.init(message: "premultiplication of rgba\(Sample.bitWidth)(\(direct.r), \(direct.g), \(direct.b), \(direct.a)) returned (\(premultiplied.r), \(premultiplied.g), \(premultiplied.b), \(premultiplied.a)), expected (\(unquantized), \(unquantized), \(unquantized), \(alpha))"))
                }
            }
        }

        return .success(())
    }
}
