import LZ77

extension PNG
{
    static
    let adam7:[(base:(x:Int, y:Int), exponent:(x:Int, y:Int))] =
    [
        (base: (0, 0), exponent: (3, 3)),
        (base: (4, 0), exponent: (3, 3)),
        (base: (0, 4), exponent: (2, 3)),
        (base: (2, 0), exponent: (2, 2)),
        (base: (0, 2), exponent: (1, 2)),
        (base: (1, 0), exponent: (1, 1)),
        (base: (0, 1), exponent: (0, 1)),
    ]

    struct Decoder
    {
        private
        var row:(index:Int, reference:[UInt8])?,
            pass:Int?
        private(set)
        var `continue`:Void?
        private
        var inflator:LZ77.Inflator
    }
}
extension PNG.Decoder
{
    init(standard:PNG.Standard, interlaced:Bool)
    {
        self.row        = nil
        self.pass       = interlaced ? 0 : nil
        self.continue   = ()

        let format:LZ77.Format
        switch standard
        {
        case .common:   format = .zlib
        case .ios:      format = .ios
        }

        self.inflator   = .init(format: format)
    }

    mutating
    func push(_ data:[UInt8], size:(x:Int, y:Int), pixel:PNG.Format.Pixel,
        delegate:(UnsafeBufferPointer<UInt8>, (x:Int, y:Int), (x:Int, y:Int)) throws -> ())
        throws -> Void?
    {
        guard let _:Void = self.continue
        else
        {
            throw PNG.DecodingError.extraneousImageDataCompressedData
        }

        self.continue = try self.inflator.push(data[...])

        let delay:Int   = (pixel.volume + 7) >> 3
        if let pass:Int = self.pass
        {
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
                    guard var scanline:[UInt8] = self.inflator.pull(last.count)
                    else
                    {
                        self.row  = (y, last)
                        self.pass = z
                        return self.continue
                    }

                    #if DUMP_FILTERED_SCANLINES
                    print("< scanline(\(scanline[0]))[\(scanline.dropFirst().prefix(8).map(String.init(_:)).joined(separator: ", ")) ... ]")
                    #endif

                    Self.defilter(&scanline, last: last, delay: delay)

                    let base:(x:Int, y:Int) = (base.x, base.y + y * stride.y)
                    try scanline.dropFirst().withUnsafeBufferPointer
                    {
                        try delegate($0, base, stride)
                    }

                    last = scanline
                }
            }
        }
        else
        {
            let pitch:Int = (size.x * pixel.volume + 7) >> 3

            var (start, last):(Int, [UInt8]) = self.row ??
                (0, .init(repeating: 0, count: pitch + 1))
            self.row = nil
            for y:Int in start ..< size.y
            {
                guard var scanline:[UInt8] = self.inflator.pull(last.count)
                else
                {
                    self.row  = (y, last)
                    return self.continue
                }

                #if DUMP_FILTERED_SCANLINES
                print("< scanline(\(scanline[0]))[\(scanline.dropFirst().prefix(8).map(String.init(_:)).joined(separator: ", ")) ... ]")
                #endif

                Self.defilter(&scanline, last: last, delay: delay)
                try scanline.dropFirst().withUnsafeBufferPointer
                {
                    try delegate($0, (0, y), (1, 1))
                }

                last = scanline
            }
        }

        self.pass = 7
        guard self.inflator.pull().isEmpty
        else
        {
            throw PNG.DecodingError.extraneousImageData
        }
        return self.continue
    }

    static
    func defilter(_ line:inout [UInt8], last:[UInt8], delay:Int)
    {
        let dataStartIndex = line.startIndex + 1
        let endIndex = line.endIndex
        switch line[line.startIndex]
        {
        case 0:
            break

        case 1: // sub
            var i:Int = dataStartIndex + delay
            while i < endIndex
            {
                line[i] &+= line[i &- delay]
                i += 1
            }

        case 2: // up
            var i:Int = dataStartIndex
            while i < endIndex
            {
                line[i] &+= last[i]
                i += 1
            }

        case 3: // average
            var i:Int = dataStartIndex
            while i < dataStartIndex + delay
            {
                line[i] &+= last[i] >> 1
                i += 1
            }
            while i < endIndex
            {
                let total:UInt16 = .init(line[i &- delay]) &+ .init(last[i])
                line[i] &+= .init(total >> 1)
                i += 1
            }

        case 4: // paeth
            var i:Int = dataStartIndex
            while i < dataStartIndex + delay
            {
                line[i] &+= PNG.paeth(0,                last[i], 0)
                i += 1
            }
            while i < endIndex
            {
                line[i] &+= PNG.paeth(line[i &- delay], last[i], last[i &- delay])
                i += 1
            }

        default:
            break // invalid
        }
    }
}
