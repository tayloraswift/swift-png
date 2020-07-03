@testable import PNG4

extension Test 
{
    static 
    var cases:[(name:String, function:Function)] 
    {
        [
            ("bitstream",                   .void(Self.bitstream)),
            ("filtering",                   .int( Self.filtering(delay:), [1, 2, 3, 4, 5, 6, 7, 8])),
            ("premultiplication (8-bit)",   .void(Self.premultiplication8)),
            ("premultiplication (16-bit)",  .void(Self.premultiplication16)),
        ]
    }
    static 
    func bitstream() -> Result<Void, Failure> 
    {
        var bits:LZ77.Inflator.In = 
        [
            0b1001_1110,
            0b1111_0110,
            0b0010_0011,
        ]
        guard   bits[ 0] == 0b1111_0110_1001_1110 ,
                bits[ 1] == 0b1_1111_0110_1001_111,
                bits[ 2] == 0b11_1111_0110_1001_11,
                bits[ 3] == 0b011_1111_0110_1001_1,
                bits[ 4] == 0b0011_1111_0110_1001 ,
                bits[ 5] == 0b0_0011_1111_0110_100,
                bits[ 6] == 0b10_0011_1111_0110_10,
                bits[ 7] == 0b010_0011_1111_0110_1,
                bits[ 8] == 0b0010_0011_1111_0110 ,
                bits[ 9] == 0b0_0010_0011_1111_011,
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
        //                       { 0010_0011, 1111_0110, 1001_1110 }
        //                            ^
        //                          b = 20
        // ->
        // { 0001_1000, 1010_1101, 0010_0011 }
        //                            ^
        //                          b = 4
        var b:Int = 20 
        bits.rebase([0b1010_1101, 0b0001_1000], pointer: &b)
        
        guard   bits[b    ] == 0b1000_1010_1101_0010, 
                bits[b + 1] == 0b1_1000_1010_1101_001
        else 
        {
            return .failure(.init(message: "incorrect rebased codeword read"))
        }
        // test rebase 
        //                       { 0001_1000, 1010_1101, 0010_0011 }
        //                                                  ^
        //                                                b = 4
        // { 1111_1100, 0011_1111, 0001_1000, 1010_1101, 0010_0011 }
        bits.rebase([0b0011_1111, 0b1111_1100], pointer: &b)
        
        guard   bits[b    ] == 0b1000_1010_1101_0010, 
                bits[b + 8] == 0b1111_0001_1000_1010
        else 
        {
            return .failure(.init(message: "incorrect rebased codeword read"))
        }
        return .success(())
    }
    
    static 
    func filtering(delay:Int) -> Result<Void, Failure> 
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
    func premultiplication8() -> Result<Void, Failure>
    {
        Self.premultiplication(for: UInt8.self, over: (.min ... .max, .min ... .max))
    }
    // exhaustive 16-bit premultiplication tests take way too long to run, so we
    // sample a select subset of the input space 
    static 
    func premultiplication16() -> Result<Void, Failure>
    {
        Self.premultiplication(for: UInt16.self, over: 
        (
            (0 ..< 512).map{ _ in .random(in: .min ... .max) },
            (0 ..< 512).map{ _ in .random(in: .min ... .max) }
        ))
    }
    static 
    func premultiplication<T, C>(for _:T.Type, over:(color:C, alpha:C)) -> Result<Void, Failure>
        where   T:FixedWidthInteger & UnsignedInteger, 
                C:Collection, C.Element == T
    {
        for color:T in over.color 
        {
            for alpha:T in over.alpha 
            {
                let direct:PNG.RGBA<T>        = .init(color, alpha),
                    premultiplied:PNG.RGBA<T> = direct.premultiplied

                let unquantized:Double  = (.init(alpha) * .init(color) / .init(T.max)),
                    quantized:T         = .init(unquantized)

                // the order is important here,, the short circuiting protects us from
                // overflow when `quantized` == 255
                guard premultiplied.r == quantized || premultiplied.r == quantized + 1
                else
                {
                    return .failure(.init(message: "premultiplication of rgba\(T.bitWidth)(\(direct.r), \(direct.g), \(direct.b), \(direct.a)) returned (\(premultiplied.r), \(premultiplied.g), \(premultiplied.b), \(premultiplied.a)), expected (\(unquantized), \(unquantized), \(unquantized), \(alpha))"))
                }
            }
        }

        return .success(())
    }
}
