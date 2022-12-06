extension PNG 
{
    struct Encoder 
    {
        enum Pass 
        {
            case subimage(Int)
            case image
        }
        
        private 
        var row:(index:Int, reference:[UInt8])?, 
            pass:Pass?
        private 
        var deflator:LZ77.Deflator 
    }
}
extension PNG.Encoder 
{
    init(standard:PNG.Standard, interlaced:Bool, level:Int, hint:Int)
    {
        self.row        = nil
        self.pass       = interlaced ? .subimage(0) : .image
        
        let format:LZ77.Format 
        switch standard 
        {
        case .common:   format = .zlib 
        case .ios:      format = .ios
        }
        
        self.deflator   = .init(format: format, level: level, 
            hint: max(1, min(hint, 0x7f_ff_ff_ff)))
    }
    
    mutating 
    func pull(size:(x:Int, y:Int), pixel:PNG.Format.Pixel, 
        delegate:(inout UnsafeMutableBufferPointer<UInt8>, (x:Int, y:Int), Int) throws -> ()) 
        rethrows -> [UInt8]?
    {
        let delay:Int   = (pixel.volume + 7) >> 3
        switch self.pass 
        {
        case .subimage(let pass)?:
            for z:Int in pass ..< 7
            {
                let (base, exponent):((x:Int, y:Int), (x:Int, y:Int)) = PNG.adam7[z]
                let stride:(x:Int, y:Int)   = 
                (
                    x: 1                                 << exponent.x, 
                    y: 1                                 << exponent.y
                )
                let subimage:(x:Int, y:Int) = 
                (
                    x: (size.x + stride.x - base.x - 1 ) >> exponent.x, 
                    y: (size.y + stride.y - base.y - 1 ) >> exponent.y
                )
                
                guard subimage.x > 0, subimage.y > 0 
                else 
                {
                    continue 
                }
                
                let pitch:Int = (subimage.x * pixel.volume + 7) >> 3
                var (start, last):(Int, [UInt8]) = self.row ?? 
                    (0, .init(repeating: 0, count: pitch + 1))
                self.row = nil 
                for y:Int in start ..< subimage.y 
                {
                    if let data:[UInt8] = self.deflator.pop() 
                    {
                        self.row  = (y, last) 
                        self.pass = .subimage(z)
                        return data 
                    }
                    // filter byte is initialized to 0
                    let scanline:[UInt8] = 
                        try .init(unsafeUninitializedCapacity: last.count) 
                    {
                        $0.baseAddress?.initialize(to: 0)
                        var tail:UnsafeMutableBufferPointer<UInt8> = 
                            .init(rebasing: $0.dropFirst())
                        try delegate(&tail, (base.x, base.y + y * stride.y), stride.x)
                        $1 = last.count
                    }
                    
                    self.deflator.push(Self.filter(scanline, last: last, delay: delay))
                    last = scanline 
                }
            }
            
            self.deflator.push([], last: true)
            self.pass = nil
        
        case .image?:
            let pitch:Int = (size.x * pixel.volume + 7) >> 3
            
            var (start, last):(Int, [UInt8]) = self.row ?? 
                (0, .init(repeating: 0, count: pitch + 1))
            self.row = nil 
            for y:Int in start ..< size.y 
            {
                if let data:[UInt8] = self.deflator.pop() 
                {
                    self.row  = (y, last) 
                    return data 
                }
                
                let scanline:[UInt8] = 
                    try .init(unsafeUninitializedCapacity: last.count) 
                {
                    $0.baseAddress?.initialize(to: 0)
                    var tail:UnsafeMutableBufferPointer<UInt8> = 
                        .init(rebasing: $0.dropFirst())
                    try delegate(&tail, (0, y), 1)
                    $1 = last.count
                }
                
                self.deflator.push(Self.filter(scanline, last: last, delay: delay))
                last = scanline 
            }
            
            self.deflator.push([], last: true)
            self.pass = nil
        
        case nil:
            break 
        }
        
        let data:[UInt8] = self.deflator.pull() 
        return data.isEmpty ? nil : data
    }
    
    static 
    func filter(_ line:[UInt8], last:[UInt8], delay:Int) -> [UInt8]
    {
        //  filtering can be done in parallel
        //  c b
        //  a x
        let current:ArraySlice<UInt8>   = line.dropFirst(), 
            last:ArraySlice<UInt8>      = last.dropFirst()
        let candidates:([UInt8], [UInt8], [UInt8], [UInt8], [UInt8]) =
        (
            line,
            [1] +     current.prefix   (delay) 
                + zip(current.dropFirst(delay),     current).map
            {
                (e:(x:UInt8,    a:UInt8) ) -> UInt8 in 
                e.x &- e.a
            },
            [2] + zip(current,                                   last).map
            {
                (e:(x:UInt8,                b:UInt8) ) -> UInt8 in 
                e.x &- e.b
            },
            [3] + zip(current.prefix   (delay),                  last.prefix   (delay) ).map
            {
                (e:(x:UInt8,                b:UInt8) ) -> UInt8 in 
                e.x &- e.b >> 1
            } 
                + zip(current.dropFirst(delay), zip(current,     last.dropFirst(delay))).map
            {
                (e:(x:UInt8, y:(a:UInt8,    b:UInt8))) -> UInt8 in
                e.x &- UInt8.init((UInt16.init(e.y.a) &+ UInt16.init(e.y.b)) >> 1)
            },
            [4] + zip(current.prefix   (delay),                  last.prefix   (delay) ).map
            {
                (e:(x:UInt8,                b:UInt8) ) -> UInt8 in 
                e.x &- PNG.paeth(0, e.b, 0)
            }
                + zip(current.dropFirst(delay), zip(current, zip(last.dropFirst(delay), last))).map
            {
                (e:(x:UInt8, y:(a:UInt8, z:(b:UInt8, c:UInt8)))) -> UInt8 in
                e.x &- PNG.paeth(e.y.a, e.y.z.b, e.y.z.c)
            }
        )
        
        let scores:[Int] = 
        [
            candidates.0, candidates.1, candidates.2, candidates.3, candidates.4
        ].map 
        {
            Self.score($0.dropFirst())
        }
        
        // i don’t know why this isn’t in the standard library
        var filter:Int  = 0,
            minimum:Int = .max
        for (i, score) in scores.enumerated()
        {
            if score < minimum
            {
                minimum = score
                filter  = i
            }
        }
        
        switch filter
        {
            case 0: return candidates.0
            case 1: return candidates.1
            case 2: return candidates.2
            case 3: return candidates.3
            case 4: return candidates.4
            default: fatalError("unreachable: 0 <= filter < 5")
        }
    } 
    
    /* private static
    func score<C>(_ filtered:C) -> Int
        where C:Sequence, C.Element == UInt8
    {
        return zip(filtered, filtered.dropFirst()).reduce(0)
        {
            $0 &+ ($1.0 != $1.1 ? 1 : 0)
        }
    } */
    
    // returns sum of squares of byte frequencies. this biases the score 
    // towards scanlines with many repeated bytes
    /* private static
    func score<C>(_ filtered:C) -> Int
        where C:Sequence, C.Element == UInt8
    {
        var frequencies:[Int] = .init(repeating: 0, count: 256)
        for byte:UInt8 in filtered 
        {
            frequencies[.init(byte)] += 1
        }
        return -frequencies.reduce(0){ $0 + $1 * $1 }
    }  */
    private static
    func score<C>(_ filtered:C) -> Int
        where C:Sequence, C.Element == UInt8
    {
        return filtered.reduce(0){ $0 + abs(.init(Int8.init(bitPattern: $1))) }
    }
}
