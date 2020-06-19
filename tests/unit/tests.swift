@testable import PNG

extension Test 
{
    static 
    var cases:[(name:String, function:Function)] 
    {
        [
            ("bitstream",                   .void(Self.bitstream)),
            ("premultiplication (8-bit)",   .void(Self.premultiplication8)),
            // ("premultiplication (16-bit)", .void(Self.premultiplication16)),
        ]
    }
    static 
    func bitstream() -> Result<Void, Failure> 
    {
        var bits:LZ77.Bitstream = 
        [
            0b1001_1110,
            0b1111_0110,
            0b0010_0011,
        ]
        guard   bits[0] == 0b0111_1001_0110_1111 ,
                bits[1] == 0b111_1001_0110_1111_1,
                bits[2] == 0b11_1001_0110_1111_11,
                bits[3] == 0b1_1001_0110_1111_110,
                bits[4] == 0b1001_0110_1111_1100 ,
                bits[5] == 0b001_0110_1111_1100_0,
                bits[6] == 0b01_0110_1111_1100_01,
                bits[7] == 0b1_0110_1111_1100_010,
                bits[8] == 0b0110_1111_1100_0100 ,
                bits[9] == 0b110_1111_1100_0100_0,
                bits[23] == 0b0000_0000_0000_0000
        else 
        {
            return .failure(.init(message: "incorrect codeword read"))
        }
        guard   bits[0, count:  4, as: Int.self] ==                   0b1110,
                bits[1, count:  4, as: Int.self] ==                 0b1_111,
                bits[1, count:  6, as: Int.self] ==               0b001_111,
                bits[2, count:  6, as: Int.self] ==              0b1001_11,
                bits[2, count: 16, as: Int.self] == 0b11_1111_0110_1001_11
        else
        {
            return .failure(.init(message: "incorrect integer read"))
        }
        
        // test rebase 
        var b:Int = 20 
        bits.rebase([0b1010_1101, 0b0001_1000], pointer: &b)
        
        guard   bits[b    ] == 0b0100_1011_0101_0001, 
                bits[b + 1] == 0b100_1011_0101_0001_1
        else 
        {
            return .failure(.init(message: "incorrect rebased codeword read"))
        }
        return .success(())
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
