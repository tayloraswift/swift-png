import Glibc
import zlib

fileprivate 
extension Array where Element == UInt8 
{    
    func load<T, U>(bigEndian:T.Type, as type:U.Type, at byte:Int) -> U 
        where T:FixedWidthInteger, U:BinaryInteger
    {
        return self[byte ..< byte + MemoryLayout<T>.size].load(bigEndian: T.self, as: U.self)
    }
}

fileprivate 
extension ArraySlice where Element == UInt8 
{
    func load<T, U>(bigEndian:T.Type, as type:U.Type) -> U 
        where T:FixedWidthInteger, U:BinaryInteger
    {
        return self.withUnsafeBufferPointer 
        {
            (buffer:UnsafeBufferPointer<UInt8>) in
            
            assert(buffer.count >= MemoryLayout<T>.size, 
                "attempt to load \(T.self) from slice of size \(buffer.count)")
            
            var storage:T = .init()
            let value:T   = withUnsafeMutablePointer(to: &storage) 
            {
                $0.deinitialize(count: 1)
                
                let source:UnsafeRawPointer     = .init(buffer.baseAddress!), 
                    raw:UnsafeMutableRawPointer = .init($0)
                
                raw.copyMemory(from: source, byteCount: MemoryLayout<T>.size)
                
                return raw.load(as: T.self)
            }
            
            return U(T(bigEndian: value))
        }
    }
}

public 
protocol DataSource
{
    // output array `.count` must equal `count`
    mutating 
    func read(count:Int) -> [UInt8]?
}

public 
enum PNG
{
    private static 
    let signature:[UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
    
    @_fixed_layout
    public
    struct RGBA<Sample>:Equatable, CustomStringConvertible 
        where Sample:FixedWidthInteger
    {
        public
        let r:Sample,
            g:Sample,
            b:Sample,
            a:Sample

        public
        var description:String
        {
            return "(\(self.r), \(self.g), \(self.b), \(self.a))"
        }

        public
        init(_ r:Sample, _ g:Sample, _ b:Sample, _ a:Sample)
        {
            self.r = r
            self.g = g
            self.b = b
            self.a = a
        }
        
        public
        init(_ r:Sample, _ g:Sample, _ b:Sample)
        {
            self.init(r, g, b, Sample.max)
        }
        
        public
        init(_ v:Sample, _ a:Sample)
        {
            self.init(v, v, v, a)
        }
        
        public
        init(_ v:Sample)
        {
            self.init(v, v, v, Sample.max)
        }

        func withAlpha(_ a:Sample) -> RGBA<Sample>
        {
            return .init(self.r, self.g, self.b, a)
        }

        func equals(opaque:RGBA<Sample>) -> Bool
        {
            return self.r == opaque.r && self.g == opaque.g && self.b == opaque.b
        }
        
        func widen<T>(to: T.Type) -> RGBA<T> where T:FixedWidthInteger 
        {
            let quantum:T = RGBA<T>.quantum(depth: Sample.bitWidth), 
                r:T = .init(truncatingIfNeeded: self.r) * quantum, 
                g:T = .init(truncatingIfNeeded: self.g) * quantum, 
                b:T = .init(truncatingIfNeeded: self.b) * quantum, 
                a:T = .init(truncatingIfNeeded: self.a) * quantum
            return .init(r, g, b, a)
        }
        
        static 
        func quantum(depth:Int) -> Sample 
        {
            return Sample.max / (Sample.max &>> (Sample.bitWidth - depth))
        }
    }
    
    public 
    struct FileInterface:DataSource 
    {
        typealias FilePointer = UnsafeMutablePointer<FILE>
        
        private 
        let descriptor:FilePointer
        
        public static 
        func open<Result>(path:String, body:(inout FileInterface) throws -> Result) rethrows -> Result? 
        {
            guard let descriptor:FilePointer = fopen(path, "rb")
            else
            {
                return nil
            }
            
            var file:FileInterface = .init(descriptor: descriptor)
            defer 
            {
                fclose(file.descriptor)
            }
            
            return try body(&file)
        }
        
        public 
        func read(count capacity:Int) -> [UInt8]?
        {
            let buffer:[UInt8] = .init(unsafeUninitializedCapacity: capacity) 
            {
                (buffer:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in 
                
                count = fread(buffer.baseAddress, MemoryLayout<UInt8>.stride, capacity, self.descriptor)
            }
            
            guard buffer.count == capacity
            else 
            {
                return nil
            }
            
            return buffer
        }
    }
    
    public static   
    func forEachChunk<Source>(in source:inout Source, body:(Math<UInt8>.V4, [UInt8]?) throws -> ()) throws
        where Source:DataSource
    {
        guard let signature:[UInt8] = source.read(count: PNG.signature.count), 
                  signature == PNG.signature
        else 
        {
            throw ReadError.missingSignature
        }
        
        while let header:[UInt8] = source.read(count: 8)
        {
            let length:Int = header.prefix(4).load(bigEndian: UInt32.self, as: Int.self)
            let name:Math<UInt8>.V4 = (header[4], header[5], header[6], header[7]) 
            
            guard var data:[UInt8] = source.read(count: length + MemoryLayout<UInt32>.size)
            else 
            {
                try body(name, nil)
                continue 
            }
            
            let checksum:UInt = data.suffix(4).load(bigEndian: UInt32.self, as: UInt.self)
            
            data.removeLast(4)
            
            let testsum:UInt  = header.suffix(4).withUnsafeBufferPointer
            {
                return crc32(crc32(0, $0.baseAddress, 4), data, UInt32(length))
            } 
            guard testsum == checksum
            else 
            {
                try body(name, nil)
                continue
            }
            
            try body(name, data)
        }
    }
    
    public 
    struct Properties
    {
        public 
        enum Format:UInt16 
        {
            // bitfield contains depth in upper byte, then code in lower byte
            case grayscale1     = 0x01_00,
                 grayscale2     = 0x02_00,
                 grayscale4     = 0x04_00,
                 grayscale8     = 0x08_00,
                 grayscale16    = 0x10_00,
                 rgb8           = 0x08_02,
                 rgb16          = 0x10_02,
                 indexed1       = 0x01_03,
                 indexed2       = 0x02_03,
                 indexed4       = 0x04_03,
                 indexed8       = 0x08_03,
                 grayscale_a8   = 0x08_04,
                 grayscale_a16  = 0x10_04,
                 rgba8          = 0x08_06,
                 rgba16         = 0x10_06
            
            var isIndexed:Bool 
            {
                return self.rawValue & 1 != 0
            }
            var hasColor:Bool 
            {
                return self.rawValue & 2 != 0
            }
            var hasAlpha:Bool 
            {
                return self.rawValue & 4 != 0
            }
            
            
            public 
            var depth:Int
            {
                return .init(self.rawValue >> 8)
            }
            
            public 
            var channels:Int
            {
                switch self
                {
                case .grayscale1, .grayscale2, .grayscale4, .grayscale8, .grayscale16,
                    .indexed1, .indexed2, .indexed4, .indexed8:
                    return 1
                case .grayscale_a8, .grayscale_a16:
                    return 2
                case .rgb8, .rgb16:
                    return 3
                case .rgba8, .rgba16:
                    return 4
                }
            }
            
            var volume:Int 
            {
                return self.depth * self.channels 
            }
            
            // difference between this and channels is indexed pngs have 3 components 
            public 
            var components:Int 
            {
                //        base +     2 × colored     +    alpha
                return .init(1 + (self.rawValue & 2) + (self.rawValue & 4) >> 2)
            }
            
            func shape(from size:Math<Int>.V2) -> Shape 
            {
                let scanlineBitCount:Int = size.x * self.channels * self.depth
                                                // ceil(scanlineBitCount / 8)
                let pitch:Int = scanlineBitCount >> 3 + (scanlineBitCount & 7 == 0 ? 0 : 1)
                return .init(pitch: pitch, size: size)
            }
        }
        
        struct Shape 
        {
            let pitch:Int, 
                size:Math<Int>.V2
            
            var byteCount:Int 
            {
                return self.pitch * self.size.y
            }
        }
        
        enum Interlacing 
        {
            struct SubImage 
            {
                let shape:Shape, 
                    strider:Math<StrideTo<Int>>.V2
            }
            
            case none, 
                 adam7([SubImage])
            
            static 
            func computeAdam7Ranges(_ subImages:[SubImage]) -> [Range<Int>]
            {
                var accumulator:Int = 0
                return subImages.map
                {
                    let upper:Int = accumulator + $0.shape.byteCount 
                    defer 
                    {
                        accumulator = upper 
                    }
                    
                    return accumulator ..< upper
                }
            }
        }
        
        struct Pitches:Sequence, IteratorProtocol 
        {
            private 
            let footprints:[(pitch:Int, height:Int)]
            
            private 
            var f:Int         = 0, 
                scanlines:Int = 0
            
            init(subImages:[Interlacing.SubImage]) 
            {
                self.footprints = subImages.map 
                {
                    ($0.shape.pitch, $0.shape.size.y)
                }
            }
            
            init(shape:Shape)
            {
                self.footprints = [(shape.pitch, shape.size.y)]
            }
            
            mutating 
            func next() -> Int?? 
            {
                let f:Int = self.f
                while self.scanlines == 0  
                {
                    guard self.f < self.footprints.count
                    else 
                    {
                        return nil  
                    }
                    
                    if self.footprints[self.f].pitch == 0 
                    {
                        self.scanlines = 0
                    }
                    else 
                    {
                        self.scanlines = self.footprints[self.f].height
                    }
                    
                    self.f += 1
                }
                
                self.scanlines -= 1 
                return self.f != f ? self.footprints[self.f - 1].pitch : .some(nil)
            }
        }
        
        // stored properties 
        public 
        let format:Format
        
        public 
        var palette:[RGBA<UInt8>]?,
            chromaKey:RGBA<UInt16>?
        
        let shape:Shape, 
            interlacing:Interlacing
        
        // computed properties 
        public 
        var interlaced:Bool
        {
            if case .adam7 = self.interlacing 
            {
                return true 
            }
            else 
            {
                return false
            }
        }
        
        var pitches:Pitches 
        {
            switch self.interlacing 
            {
                case .none:
                    return .init(shape: self.shape)
                
                case .adam7(let subImages):
                    return .init(subImages: subImages)
            }
        }
            
        public 
        init(size:Math<Int>.V2, format:Format, interlaced:Bool, 
            palette:[RGBA<UInt8>]? = nil, chromaKey:RGBA<UInt16>? = nil)
        {
            self.format = format
            self.shape  = format.shape(from: size)
            
            if interlaced 
            {
                // calculate size of interlaced subimages
                // 0: (w + 7) >> 3 , (h + 7) >> 3
                // 1: (w + 3) >> 3 , (h + 7) >> 3
                // 2: (w + 3) >> 2 , (h + 3) >> 3
                // 3: (w + 1) >> 2 , (h + 3) >> 2
                // 4: (w + 1) >> 1 , (h + 1) >> 2
                // 5: (w) >> 1     , (h + 1) >> 1
                // 6: (w)          , (h) >> 1
                let sizes:[Math<Int>.V2] = 
                [
                    ((size.x + 7) >> 3, (size.y + 7) >> 3),
                    ((size.x + 3) >> 3, (size.y + 7) >> 3),
                    ((size.x + 3) >> 2, (size.y + 3) >> 3),
                    ((size.x + 1) >> 2, (size.y + 3) >> 2),
                    ((size.x + 1) >> 1, (size.y + 1) >> 2),
                    ( size.x      >> 1, (size.y + 1) >> 1),
                    ( size.x      >> 0,  size.y      >> 1)
                ]
                
                let striders:[Math<StrideTo<Int>>.V2] = 
                [
                    (stride(from: 0, to: size.x, by: 8), stride(from: 0, to: size.y, by: 8)),
                    (stride(from: 4, to: size.x, by: 8), stride(from: 0, to: size.y, by: 8)),
                    (stride(from: 0, to: size.x, by: 4), stride(from: 4, to: size.y, by: 8)),
                    (stride(from: 2, to: size.x, by: 4), stride(from: 0, to: size.y, by: 4)),
                    (stride(from: 0, to: size.x, by: 2), stride(from: 2, to: size.y, by: 4)),
                    (stride(from: 1, to: size.x, by: 2), stride(from: 0, to: size.y, by: 2)),
                    (stride(from: 0, to: size.x, by: 1), stride(from: 1, to: size.y, by: 2))
                ]
                
                let subImages:[Interlacing.SubImage] = zip(sizes, striders).map
                {
                    (size:Math<Int>.V2, strider:Math<StrideTo<Int>>.V2) in 
                    
                    return .init(shape: format.shape(from: size), strider: strider)
                }
                
                self.interlacing = .adam7(subImages)
            }
            else 
            {
                self.interlacing = .none
            }
            
            self.palette   = palette 
            self.chromaKey = chromaKey
        }
        
        
        func decoder() -> Decoder?
        {
            return ZDecompressor().map
            {
                let stride:Int = max(1, self.format.volume >> 3)
                return .init(stride: stride, pitches: self.pitches, decompressor: $0)
            }
        }
        
        struct Decoder 
        {
            private 
            var reference:[UInt8]?, 
                scanline:[UInt8] = []
            
            private 
            let stride:Int
            
            private   
            var pitches:Pitches, 
                decompressor:ZDecompressor
            
            init(stride:Int, pitches:Pitches, decompressor:ZDecompressor)
            {
                self.stride       = stride 
                self.pitches      = pitches
                self.decompressor = decompressor
                
                guard let pitch:Int = self.pitches.next() ?? nil
                else 
                {
                    return 
                }
                
                self.reference = .init(repeating: 0, count: pitch + 1)
            }
            
            mutating 
            func forEachScanline(decodedFrom data:[UInt8], body:(ArraySlice<UInt8>) throws -> ()) throws
            {
                self.decompressor.push(data)
                
                while let reference:[UInt8] = self.reference  
                {
                    try self.decompressor.pull(extending: &self.scanline, 
                                                capacity: reference.count) 
                    
                    guard self.scanline.count == reference.count
                    else 
                    {
                        break
                    }
                    
                    self.defilter(scanline: &self.scanline, reference: reference)
                    
                    try body(self.scanline.dropFirst())
                    
                    // transfer scanline to reference line 
                    if let pitch:Int? = self.pitches.next() 
                    {
                        if let pitch:Int = pitch 
                        {
                            self.reference = .init(repeating: 0, count: pitch + 1)
                        }
                        else 
                        {
                            self.reference = self.scanline 
                        }
                    }
                    else 
                    {
                        self.reference = nil 
                    }
                    
                    self.scanline = []
                }
            }
            
            private  
            func defilter(scanline:inout [UInt8], reference:[UInt8])
            {
                let filter:UInt8              = scanline[scanline.startIndex] 
                scanline[scanline.startIndex] = 0
                switch filter
                {
                    case 0:
                        break 
                    
                    case 1: // sub 
                        for i:Int in scanline.indices.dropFirst(self.stride)
                        {
                            scanline[i] = scanline[i] &+ scanline[i - self.stride]
                        }
                    
                    case 2: // up 
                        for i:Int in scanline.indices
                        {
                            scanline[i] = scanline[i] &+ reference[i]
                        }
                    
                    case 3: // average 
                        for i:Int in scanline.indices.prefix(self.stride)
                        {
                            scanline[i] = scanline[i] &+ reference[i] >> 1
                        }
                        for i:Int in scanline.indices.dropFirst(self.stride) 
                        {
                            let total:UInt16  = UInt16(scanline[i - self.stride]) + 
                                                UInt16(reference[i])
                            scanline[i] = scanline[i] &+ UInt8(truncatingIfNeeded: total >> 1)
                        }
                    
                    case 4: // paeth 
                        for i:Int in scanline.indices.prefix(self.stride)
                        {
                            scanline[i] = scanline[i] &+ paeth(0, reference[i], 0)
                        }
                        for i:Int in scanline.indices.dropFirst(self.stride) 
                        {
                            let p:UInt8 =  paeth(scanline[i - self.stride], 
                                                reference[i              ], 
                                                reference[i - self.stride])
                            scanline[i] = scanline[i] &+ p
                        }
                    
                    default:
                        break // invalid
                }
            }
        }
        
        static 
        func decodeIHDR(_ data:[UInt8]) throws -> Properties
        {
            guard data.count == 13 
            else 
            {
                throw ReadError.syntaxError(message: "png header length is \(data.count), expected 13")
            }
            
            let colorcode:UInt16 = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 8)
            guard let format:Format = Format.init(rawValue: colorcode)
            else 
            {
                throw ReadError.syntaxError(message: "color format bytes have invalid values (\(data[8]), \(data[9]))")
            }
            
            // validate other fields 
            guard data[10] == 0 
            else 
            {
                throw ReadError.syntaxError(message: "compression byte has value \(data[10]), expected 0")
            }
            guard data[11] == 0 
            else 
            {
                throw ReadError.syntaxError(message: "filter byte has value \(data[11]), expected 0")
            }
            
            let interlaced:Bool 
            switch data[12]
            {
                case 0:
                    interlaced = false 
                case 1: 
                    interlaced = true 
                default:
                    throw ReadError.syntaxError(message: "interlacing byte has invalid value \(data[12])")
            }
            
            let width:Int  = data.load(bigEndian: UInt32.self, as: Int.self, at: 0), 
                height:Int = data.load(bigEndian: UInt32.self, as: Int.self, at: 4)
            
            return .init(size: (width, height), format: format, interlaced: interlaced)
        }
        
        mutating 
        func decodePLTE(_ data:[UInt8]) throws
        {
            guard data.count.isMultiple(of: 3)
            else
            {
                throw ReadError.syntaxError(message: "palette does not contain a whole number of entries (\(data.count) bytes)")
            }
            
            // check number of palette entries 
            let maxEntries:Int = 1 << self.format.depth
            guard data.count <= maxEntries * 3
            else 
            {
                throw ReadError.syntaxError(message: "palette contains too many entries (found \(data.count / 3), expected\(maxEntries))")
            }

            self.palette = stride(from: data.startIndex, to: data.endIndex, by: 3).map
            {
                let r:UInt8 = data[$0    ],
                    g:UInt8 = data[$0 + 1],
                    b:UInt8 = data[$0 + 2]
                return .init(r, g, b)
            }
        }
        
        mutating 
        func decodetRNS(_ data:[UInt8]) throws
        {
            switch self.format
            {
                case .grayscale1, .grayscale2, .grayscale4, .grayscale8, .grayscale16:
                    guard data.count == 2
                    else
                    {
                        throw ReadError.syntaxError(message: "grayscale chroma key has wrong size (\(data.count) bytes, expected 2 bytes)")
                    }
                    
                    let quantum:UInt16 = RGBA<UInt16>.quantum(depth: self.format.depth), 
                        v:UInt16   = quantum * data.load(bigEndian: UInt16.self, as: UInt16.self, at: 0)
                    self.chromaKey = .init(v)
                
                case .rgb8, .rgb16:
                    guard data.count == 6
                    else
                    {
                        throw ReadError.syntaxError(message: "rgb chroma key has wrong size (\(data.count) bytes, expected 6 bytes)")
                    }
                    
                    let quantum:UInt16 = RGBA<UInt16>.quantum(depth: self.format.depth), 
                        r:UInt16   = quantum * data.load(bigEndian: UInt16.self, as: UInt16.self, at: 0), 
                        g:UInt16   = quantum * data.load(bigEndian: UInt16.self, as: UInt16.self, at: 2), 
                        b:UInt16   = quantum * data.load(bigEndian: UInt16.self, as: UInt16.self, at: 4)
                    self.chromaKey = .init(r, g, b)
                
                case .indexed1, .indexed2, .indexed4, .indexed8:
                    guard let palette:[RGBA<UInt8>] = self.palette
                    else
                    {
                        throw PNGReadError.MissingPalatteError
                    }

                    guard data.count <= palette.count
                    else
                    {
                        throw ReadError.syntaxError(message: "indexed image contains too many transparency entries (\(data.count), expected \(palette.count))")
                    }

                    for (i, alpha):(Int, UInt8) in zip(palette.indices, data)
                    {
                        self.palette?[i] = palette[i].withAlpha(alpha)
                    }
                    
                    self.chromaKey = nil
                
                default:
                    break // this is an error, but it should have already been caught by PNGConditions
            }
        }
    }
    
    enum Data 
    {
        // PNG data that has been decompressed, but not necessarily deinterlaced 
        struct Uncompressed 
        {
            let properties:Properties, 
                data:[UInt8]
            
            func decompose() -> [Rectangular]?
            {
                guard case .adam7(let subImages) = self.properties.interlacing 
                else 
                {
                    return nil
                }
                
                let ranges:[Range<Int>] = Properties.Interlacing.computeAdam7Ranges(subImages)
                
                assert(self.data.count == ranges[6].upperBound)
                
                return zip(ranges, subImages).map 
                {
                    (range:Range<Int>, subImage:Properties.Interlacing.SubImage) in 
                    
                    let properties:Properties = .init(size: subImage.shape.size, 
                                                    format: self.properties.format, 
                                                interlaced: false)
                    
                    return .init(properties: properties, data: .init(self.data[range]))
                }
            }
            
            func deinterlace() -> Rectangular 
            {
                guard case .adam7(let subImages) = self.properties.interlacing 
                else 
                {
                    // image is not interlaced at all, return it transparently 
                    assert(self.data.count == self.properties.shape.byteCount)
                    return .init(properties: self.properties, data: self.data)
                }
                
                let properties:Properties = .init(size: self.properties.shape.size, 
                                                format: self.properties.format, 
                                            interlaced: false, 
                                               palette: self.properties.palette, 
                                             chromaKey: self.properties.chromaKey)
                
                let capacity:Int = properties.shape.byteCount
                let deinterlaced:[UInt8] = .init(unsafeUninitializedCapacity: capacity)
                {
                    (buffer:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in
                    
                    let volume:Int = properties.format.volume
                    if volume < 8 
                    {
                        // initialize the buffer to 0. this makes it so we can store 
                        // bits into the buffer without needing to mask them out 
                        buffer.initialize(repeating: 0)
                        
                        var base:Int = self.data.startIndex 
                        for subImage:Properties.Interlacing.SubImage in subImages 
                        {
                            for (sy, dy):(Int, Int) in subImage.strider.y.enumerated()
                            {
                                for (sx, dx):(Int, Int) in subImage.strider.x.enumerated()
                                {
                                    // image only has 1 channel 
                                    let si:Int = (sx * volume) >> 3 + subImage.shape.pitch   * sy, 
                                        di:Int = (dx * volume) >> 3 + properties.shape.pitch * dy
                                    let sb:Int = (sx * volume) & 7, 
                                        db:Int = (dx * volume) & 7
                                    
                                    // isolate relevant bits and store them into the destination
                                    let empty:Int  = UInt8.bitWidth - volume, 
                                        bits:UInt8 = (self.data[base + si] &<< sb) &>> empty
                                    buffer[di]    |= bits &<< (empty - db)
                                }
                            }
                            
                            base += subImage.shape.byteCount
                        }
                    }
                    else 
                    {
                        let stride:Int = volume >> 3
                        
                        var base:Int = self.data.startIndex 
                        for subImage:Properties.Interlacing.SubImage in subImages 
                        {
                            for (sy, dy):(Int, Int) in subImage.strider.y.enumerated()
                            {                            
                                for (sx, dx):(Int, Int) in subImage.strider.x.enumerated()
                                {
                                    let si:Int = sx * stride + subImage.shape.pitch   * sy, 
                                        di:Int = dx * stride + properties.shape.pitch * dy
                                    
                                    for b:Int in 0 ..< stride 
                                    {
                                        buffer[di + b] = self.data[base + si + b]
                                    }
                                }
                            }
                            
                            base += subImage.shape.byteCount
                        }
                    }
                    
                    count = capacity
                }
                
                return .init(properties: properties, data: deinterlaced)
            }
        }
        
        // PNG data that has been deinterlaced, but may still have multiple pixels 
        // packed per byte, or indirect (indexed) pixels
        struct Rectangular 
        {
            let properties:Properties, 
                data:[UInt8]
            
            static 
            func index(_ pixels:[RGBA<UInt8>], size:Math<Int>.V2) -> Rectangular 
            {
                fatalError("unimplemented")
            }
            
            func expand8() -> [UInt8]
            {
                return []
            }
            
            func expand16() -> [UInt16]
            {
                return []
            }
            
            func grayscale8() -> [UInt8] 
            {
                return []
            }
            
            func grayscale16() -> [UInt16]
            {
                return []
            }
            
            func rgba8() -> [RGBA<UInt8>]
            {
                return []
            }
            
            func rgba16() -> [RGBA<UInt16>]?
            {
                @inline(__always) 
                func _greenscreen(_ color:RGBA<UInt16>) -> RGBA<UInt16> 
                {
                    guard let key:RGBA<UInt16> = self.properties.chromaKey 
                    else 
                    {
                        return color
                    }
                    
                    return color.equals(opaque: key) ? color.withAlpha(0) : color
                }
                @inline(__always) 
                func _greenscreen(v:UInt16) -> RGBA<UInt16> 
                {
                    return _greenscreen(.init(v))
                }
                @inline(__always) 
                func _greenscreen(r:UInt16, g:UInt16, b:UInt16) -> RGBA<UInt16> 
                {
                    return _greenscreen(.init(r, g, b))
                }
                
                switch self.properties.format 
                {
                    case .grayscale1, .grayscale2, .grayscale4:
                        return self.mapBits(_greenscreen(v:)) 
                    
                    case .grayscale8:
                        return self.map(from: UInt8.self, _greenscreen(v:)) 
                    
                    case .grayscale16:
                        return self.map(from: UInt16.self, _greenscreen(v:)) 
                    
                    case .grayscale_a8:
                        return self.map(from: UInt8.self, RGBA.init(_:_:)) 
                    
                    case .grayscale_a16:
                        return self.map(from: UInt16.self, RGBA.init(_:_:)) 
                    
                    case .rgb8:
                        return self.map(from: UInt8.self, _greenscreen(r:g:b:)) 
                    
                    case .rgb16:
                        return self.map(from: UInt16.self, _greenscreen(r:g:b:)) 
                    
                    case .rgba8:
                        return self.map(from: UInt8.self, RGBA.init(_:_:_:_:)) 
                    
                    case .rgba16:
                        return self.map(from: UInt16.self, RGBA.init(_:_:_:_:)) 
                        
                    case .indexed1, .indexed2, .indexed4:
                        guard let palette:[RGBA<UInt8>] = self.properties.palette 
                        else 
                        {
                            // missing palette, should never occur in normal circumstances
                            return nil
                        }
                        
                        return self.mapScalarBits 
                        {
                            return palette[Int($0)].widen(to: UInt16.self)
                        }
                    
                    case .indexed8:
                        guard let palette:[RGBA<UInt8>] = self.properties.palette 
                        else 
                        {
                            // missing palette, should never occur in normal circumstances
                            return nil
                        }
                        
                        // we want raw scalars 
                        return self.map(narrowing: UInt8.self)
                        {
                            (scalar:UInt8) in 
                            
                            return palette[Int(scalar)].widen(to: UInt16.self)
                        }
                }
            }
            
            @inline(__always)
            private 
            func extract(bits:Int, at bitIndex:Int) -> UInt8 
            {
                let byte:Int      = bitIndex >> 3, 
                    bit:Int       = bitIndex & 7, 
                    offset:Int    = UInt8.bitWidth - bits
                return (self.data[byte] &<< bit) &>> offset
            }
            
            @inline(__always)
            private 
            func extract<T, Sample>(bigEndian:T.Type, at index:Int, as:Sample.Type) -> Sample 
                where T:FixedWidthInteger, Sample:FixedWidthInteger
            {
                assert(T.bitWidth <= Sample.bitWidth)
                
                let scalar:Sample = self.data.withUnsafeBufferPointer 
                {
                    let offset:Int               = index * MemoryLayout<T>.stride, 
                        raw:UnsafeRawPointer     = .init($0.baseAddress! + offset), 
                        pointer:UnsafePointer<T> = raw.bindMemory(to: T.self, capacity: 1)
                    return Sample(truncatingIfNeeded: T(bigEndian: pointer.pointee))
                }
                
                return scalar * RGBA<Sample>.quantum(depth: self.properties.format.depth)
            }
            
            @inline(__always)
            private 
            func narrow<T, Sample>(bigEndian:T.Type, at index:Int, as:Sample.Type) -> Sample 
                where T:FixedWidthInteger, Sample:FixedWidthInteger
            {
                assert(T.bitWidth >= Sample.bitWidth)
                
                return self.data.withUnsafeBufferPointer 
                {
                    let offset:Int               = index * MemoryLayout<T>.stride, 
                        raw:UnsafeRawPointer     = .init($0.baseAddress! + offset), 
                        pointer:UnsafePointer<T> = raw.bindMemory(to: T.self, capacity: 1)
                    let shift:Int = T.bitWidth - Sample.bitWidth
                    return Sample(truncatingIfNeeded: T(bigEndian: pointer.pointee) &>> shift)
                }
            }
            
            private 
            func mapScalarBits<Result>(_ body:(UInt8) -> Result) -> [Result] 
            {
                assert(self.data.count == self.properties.shape.byteCount)
                assert(self.properties.format.depth < UInt8.bitWidth)
                
                return withoutActuallyEscaping(body)
                {
                    (body:@escaping (UInt8) -> Result) in
                    
                    let depth:Int = self.properties.format.depth, 
                        count:Int = self.properties.format.volume * self.properties.shape.size.x
                    return stride(from: 0, to: self.data.count, by: self.properties.shape.pitch).flatMap 
                    {
                        (i:Int) -> LazyMapSequence<StrideTo<Int>, Result> in
                        
                        let base:Int = i << 3
                        return stride(from: base, to: base + count, by: depth).lazy.map 
                        {
                            body(self.extract(bits: depth, at: $0))
                        }
                    }
                }
            }
            private 
            func mapBits<Sample, Result>(_ body:(Sample) -> Result) -> [Result] 
                 where Sample:FixedWidthInteger
            {
                return self.mapScalarBits 
                {
                    let scalar:Sample = .init(truncatingIfNeeded: $0) 
                    return body(scalar * RGBA<Sample>.quantum(depth: self.properties.format.depth))
                }
            }
            
            private 
            func map<Atom, Sample, Result>(from _:Atom.Type, _ body:(Sample) -> Result) -> [Result] 
                 where Atom:FixedWidthInteger, Sample:FixedWidthInteger
            {
                assert(self.data.count == self.properties.shape.byteCount)
                assert(self.properties.format.depth == Atom.bitWidth)
                
                return (0 ..< Math.vol(self.properties.shape.size)).map 
                {
                    return body(self.extract(bigEndian: Atom.self, at: $0, as: Sample.self))
                }
            }
            
            private 
            func map<Atom, Sample, Result>(narrowing _:Atom.Type, _ body:(Sample) -> Result) -> [Result] 
                 where Atom:FixedWidthInteger, Sample:FixedWidthInteger
            {
                assert(self.data.count == self.properties.shape.byteCount)
                assert(self.properties.format.depth == Atom.bitWidth)
                
                return (0 ..< Math.vol(self.properties.shape.size)).map 
                {
                    return body(self.narrow(bigEndian: Atom.self, at: $0, as: Sample.self))
                }
            }
            
            
            private 
            func map<Atom, Sample, Result>(from _:Atom.Type, _ body:(Sample, Sample) -> Result) -> [Result] 
                 where Atom:FixedWidthInteger, Sample:FixedWidthInteger
            {
                assert(self.data.count == self.properties.shape.byteCount)
                assert(self.properties.format.depth == Atom.bitWidth)
                
                return (0 ..< Math.vol(self.properties.shape.size)).map 
                {
                    return body(
                        self.extract(bigEndian: Atom.self, at: $0 << 1,     as: Sample.self), 
                        self.extract(bigEndian: Atom.self, at: $0 << 1 | 1, as: Sample.self))
                }
            }
            
            private 
            func map<Atom, Sample, Result>(narrowing _:Atom.Type, _ body:(Sample, Sample) -> Result) -> [Result] 
                 where Atom:FixedWidthInteger, Sample:FixedWidthInteger
            {
                assert(self.data.count == self.properties.shape.byteCount)
                assert(self.properties.format.depth == Atom.bitWidth)
                
                return (0 ..< Math.vol(self.properties.shape.size)).map 
                {
                    return body(
                        self.narrow(bigEndian: Atom.self, at: $0 << 1,      as: Sample.self), 
                        self.narrow(bigEndian: Atom.self, at: $0 << 1 | 1,  as: Sample.self))
                }
            }
            
            
            private 
            func map<Atom, Sample, Result>(from _:Atom.Type, _ body:(Sample, Sample, Sample) -> Result) -> [Result] 
                 where Atom:FixedWidthInteger, Sample:FixedWidthInteger
            {
                assert(self.data.count == self.properties.shape.byteCount)
                assert(self.properties.format.depth == Atom.bitWidth)
                
                return (0 ..< Math.vol(self.properties.shape.size)).map 
                {
                    return body(
                        self.extract(bigEndian: Atom.self, at: $0 * 3,      as: Sample.self), 
                        self.extract(bigEndian: Atom.self, at: $0 * 3 + 1,  as: Sample.self), 
                        self.extract(bigEndian: Atom.self, at: $0 * 3 + 2,  as: Sample.self))
                }
            }
            
            private 
            func map<Atom, Sample, Result>(narrowing _:Atom.Type, _ body:(Sample, Sample, Sample) -> Result) -> [Result] 
                 where Atom:FixedWidthInteger, Sample:FixedWidthInteger
            {
                assert(self.data.count == self.properties.shape.byteCount)
                assert(self.properties.format.depth == Atom.bitWidth)
                
                return (0 ..< Math.vol(self.properties.shape.size)).map 
                {
                    return body(
                        self.narrow(bigEndian: Atom.self, at: $0 * 3,      as: Sample.self), 
                        self.narrow(bigEndian: Atom.self, at: $0 * 3 + 1,  as: Sample.self), 
                        self.narrow(bigEndian: Atom.self, at: $0 * 3 + 2,  as: Sample.self))
                }
            }
            
            
            private 
            func map<Atom, Sample, Result>(from _:Atom.Type, _ body:(Sample, Sample, Sample, Sample) -> Result) -> [Result] 
                 where Atom:FixedWidthInteger, Sample:FixedWidthInteger
            {
                assert(self.data.count == self.properties.shape.byteCount)
                assert(self.properties.format.depth == Atom.bitWidth)
                
                return (0 ..< Math.vol(self.properties.shape.size)).map 
                {
                    return body(
                        self.extract(bigEndian: Atom.self, at: $0 << 2,      as: Sample.self), 
                        self.extract(bigEndian: Atom.self, at: $0 << 2 | 1,  as: Sample.self), 
                        self.extract(bigEndian: Atom.self, at: $0 << 2 | 2,  as: Sample.self), 
                        self.extract(bigEndian: Atom.self, at: $0 << 2 | 3,  as: Sample.self))
                }
            }
            
            private 
            func map<Atom, Sample, Result>(narrowing _:Atom.Type, _ body:(Sample, Sample, Sample, Sample) -> Result) -> [Result] 
                 where Atom:FixedWidthInteger, Sample:FixedWidthInteger
            {
                assert(self.data.count == self.properties.shape.byteCount)
                assert(self.properties.format.depth == Atom.bitWidth)
                
                return (0 ..< Math.vol(self.properties.shape.size)).map 
                {
                    return body(
                        self.narrow(bigEndian: Atom.self, at: $0 << 2,      as: Sample.self), 
                        self.narrow(bigEndian: Atom.self, at: $0 << 2 | 1,  as: Sample.self), 
                        self.narrow(bigEndian: Atom.self, at: $0 << 2 | 2,  as: Sample.self), 
                        self.narrow(bigEndian: Atom.self, at: $0 << 2 | 3,  as: Sample.self))
                }
            }
        }
    }
    
    public 
    struct Chunk:Hashable, Equatable, CustomStringConvertible
    {
        let name:Math<UInt8>.V4
        
        public
        var description:String 
        {
            return .init( decoding: [self.name.0, self.name.1, self.name.2, self.name.3], 
                                as: Unicode.ASCII.self)
        }
        
        private 
        init(_ a:UInt8, _ p:UInt8, _ r:UInt8, _ c:UInt8)
        {
            self.name = (a, p, r, c)
        }
        
        public  
        init?(_ name:Math<UInt8>.V4)
        {
            self.name = name
            switch self 
            {
                // legal public chunks 
                case .IHDR, .PLTE, .IDAT, .IEND, 
                     .cHRM, .gAMA, .iCCP, .sBIT, .sRGB, .bKGD, .hIST, .tRNS, 
                     .pHYs, .sPLT, .tIME, .iTXt, .tEXt, .zTXt:
                    break 

                default:
                    guard name.0 & 0x20 != 0 
                    else 
                    {
                        return nil
                    }

                    guard name.2 & 0x20 == 0 
                    else 
                    {
                        return nil
                    }
            }
        }
        
        public static 
        func == (a:Chunk, b:Chunk) -> Bool 
        {
            return a.name == b.name
        }
        
        public 
        func hash(into hasher:inout Hasher) 
        {
            hasher.combine( self.name.0 << 24 | 
                            self.name.1 << 16 | 
                            self.name.2 <<  8 | 
                            self.name.3)
        }
        
        static 
        let IHDR:Chunk = .init(73, 72, 68, 82), 
            PLTE:Chunk = .init(80, 76, 84, 69), 
            IDAT:Chunk = .init(73, 68, 65, 84), 
            IEND:Chunk = .init(73, 69, 78, 68), 
            
            cHRM:Chunk = .init(99, 72, 82, 77), 
            gAMA:Chunk = .init(103, 65, 77, 65), 
            iCCP:Chunk = .init(105, 67, 67, 80), 
            sBIT:Chunk = .init(115, 66, 73, 84), 
            sRGB:Chunk = .init(115, 82, 71, 66), 
            bKGD:Chunk = .init(98, 75, 71, 68), 
            hIST:Chunk = .init(104, 73, 83, 84), 
            tRNS:Chunk = .init(116, 82, 78, 83), 
            
            pHYs:Chunk = .init(112, 72, 89, 115), 
            
            sPLT:Chunk = .init(115, 80, 76, 84), 
            tIME:Chunk = .init(116, 73, 77, 69), 
            
            iTXt:Chunk = .init(105, 84, 88, 116), 
            tEXt:Chunk = .init(116, 69, 88, 116), 
            zTXt:Chunk = .init(122, 84, 88, 116)
    }
    
    enum ReadError:Error
    {
        case incompleteChunk,  
            
             syntaxError(message: String), 
             
             missingSignature, 
             missingHeader, 
             prematureIEND, 
             corruptedChunk, 
             illegalChunk(Chunk), 
             misplacedChunk(Chunk), 
             duplicateChunk(Chunk), 
             missingPalette
    }

    // performs chunk ordering and presence validation
    struct Conditions 
    {
        private 
        var format:Properties.Format?, 
            last:Chunk?, 
            seen:Set<Chunk> = []
        
        mutating 
        func push(_ chunk:Chunk) -> ReadError? 
        {
            guard let last:Chunk = self.last
            else 
            {
                guard chunk == .IHDR
                else 
                {
                    return .missingHeader 
                }
                
                self.last = .IHDR
                self.seen.insert(.IHDR)
                return nil 
            }
            
            guard last != .IEND
            else 
            {
                return .prematureIEND
            }
            
            guard let format:Properties.Format = self.format
            else 
            {
                return .missingHeader
            }
        
            if      chunk ==                                                                  .tRNS
            {
                guard !format.hasAlpha // tRNS forbidden in alpha’d formats
                else
                {
                    return .illegalChunk(chunk)
                }
            }
            else if chunk ==   .PLTE
            {
                // PLTE must come before bKGD, hIST, and tRNS
                guard format.hasColor // PLTE requires non-grayscale format
                else
                {
                    return .illegalChunk(chunk)
                }

                if self.seen.contains(.bKGD) || self.seen.contains(.hIST) || self.seen.contains(.tRNS)
                {
                    return .misplacedChunk(chunk)
                }
            }

            // these chunks must occur before PLTE
            switch chunk
            {
                case                         .cHRM, .gAMA, .iCCP, .sBIT, .sRGB:
                    if self.seen.contains(.PLTE)
                    {
                        return .misplacedChunk(chunk)
                    }
                    
                    fallthrough 
                
                // these chunks (and the ones in previous cases) must occur before IDAT
                case           .PLTE,                                           .bKGD, .hIST, .tRNS, .pHYs, .sPLT:
                    if self.seen.contains(.IDAT)
                    {
                        return .misplacedChunk(chunk)
                    }
                    
                    fallthrough 
                
                // these chunks (and the ones in previous cases) cannot duplicate
                case    .IHDR,                                                                                     .tIME:
                    if self.seen.contains(chunk)
                    {
                        return .duplicateChunk(chunk)
                    }
                
                
                // IDAT blocks much be consecutive
                case .IDAT:
                    if  last != .IDAT, 
                        self.seen.contains(.IDAT)
                    {
                        return .misplacedChunk(.IDAT)
                    }

                    if  format.isIndexed, 
                       !self.seen.contains(.PLTE)
                    {
                        return .missingPalette
                    }
                    
                default:
                    break
            }
            
            self.seen.insert(chunk)
            self.last = chunk
            return nil
        }
    }
}
