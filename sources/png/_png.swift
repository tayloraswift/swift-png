import Glibc
import zlib

fileprivate 
extension ArraySlice where Element == UInt8 
{
    func load<T, U>(bigEndian:T.Type, as type:U.Type) -> U 
        where T:FixedWidthInteger, U:BinaryInteger
    {
        return self.withUnsafeBufferPointer 
        {
            (buffer:UnsafeBufferPointer<UInt8>) in
            
            var storage:T = .init()
            let value:T   = withUnsafeMutablePointer(to: &storage) 
            {
                $0.deinitialize(count: 1)
                
                guard buffer.count >= MemoryLayout<T>.size, 
                  let source:UnsafeRawPointer = buffer.baseAddress.map(UnsafeRawPointer.init(_:))
                else 
                {
                    fatalError("attempt to load \(T.self) from buffer of size \(buffer.count)")
                }
                
                let raw:UnsafeMutableRawPointer = .init($0)
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
    // output array `.count` must equal `bytes`
    mutating 
    func read(bytes:Int) -> [UInt8]?
}

public 
enum PNG
{
    private static 
    let signature:[UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
    
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
        func read(bytes:Int) -> [UInt8]?
        {
            let buffer:[UInt8] = .init(unsafeUninitializedCapacity: bytes) 
            {
                (buffer:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in 
                
                count = fread(buffer.baseAddress, 1, bytes, self.descriptor)
            }
            
            guard buffer.count == bytes 
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
        guard let signature:[UInt8] = source.read(bytes: PNG.signature.count), 
                  signature == PNG.signature
        else 
        {
            throw ReadError.missingSignature
        }
        
        while let header:[UInt8] = source.read(bytes: 8)
        {
            let length:Int = header.prefix(4).load(bigEndian: UInt32.self, as: Int.self)
            let name:Math<UInt8>.V4 = (header[4], header[5], header[6], header[7]) 
            
            guard var data:[UInt8] = source.read(bytes: length + MemoryLayout<UInt32>.size)
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
                    
                    self.scanlines = self.footprints[self.f].pitch * self.footprints[self.f].height
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
        init(size:Math<Int>.V2, format:Format, interlaced:Bool)
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
        }
        
        func decoder() -> Decoder?
        {
            return ZDecompressor().map
            {
                .init(pitches: self.pitches, decompressor: $0)
            }
        }
        
        struct Decoder 
        {
            private 
            var reference:[UInt8]?, 
                scanline:[UInt8], 
                decompressor:ZDecompressor, 
                pitches:Pitches
            
            init(pitches:Pitches, decompressor:ZDecompressor)
            {
                self.pitches   = pitches
                self.scanline  = []
                
                
                
                self.decompressor = decompressor
                
                guard let pitch:Int = self.pitches.next() ?? nil
                else 
                {
                    self.reference = nil 
                    return 
                }
                
                self.reference = .init(repeating: 0, count: pitch + 1)
            }
            
            mutating 
            func add(data:[UInt8]) throws
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
                    
                    
                    
                    if let pitch:Int? = self.pitches.next() 
                    {
                        if let pitch:Int = pitch 
                        {
                            self.reference = .init(repeating: 0, count: pitch + 1)
                        }
                        else 
                        {
                            // reuse the filter byte
                            self.scanline[0] = 0
                            self.reference   = self.scanline 
                        }
                    }
                    else 
                    {
                        self.reference = nil 
                    }
                    
                    self.scanline = []
                }
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
                                            interlaced: false)
                let count:Int = properties.shape.byteCount
                let deinterlaced:[UInt8] = .init(unsafeUninitializedCapacity: count)
                {
                    (buffer:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in
                    
                    let depth:Int = properties.format.depth
                    if depth < 8 
                    {
                        var base:Int = self.data.startIndex 
                        for subImage:Properties.Interlacing.SubImage in subImages 
                        {
                            for (sy, dy):(Int, Int) in subImage.strider.y.enumerated()
                            {                            
                                for (sx, dx):(Int, Int) in subImage.strider.x.enumerated()
                                {
                                    // image only has 1 channel 
                                    let si:Int = (sx * depth) >> 3 + subImage.shape.pitch   * sy, 
                                        di:Int = (dx * depth) >> 3 + properties.shape.pitch * dy
                                    let sb:Int = (sx * depth) & 7, 
                                        db:Int = (dx * depth) & 7
                                    
                                    // isolate relevant bits and store them into the destination
                                    let bits:UInt8 = (self.data[base + si] &<< sb) &>> (8 - depth)
                                    buffer[di]    |= bits &<< (8 - db - depth) 
                                }
                            }
                            
                            base += subImage.shape.byteCount
                        }
                    }
                    else 
                    {
                        let bpp:Int = (properties.format.channels * depth) >> 3
                        
                        var base:Int = self.data.startIndex 
                        for subImage:Properties.Interlacing.SubImage in subImages 
                        {
                            for (sy, dy):(Int, Int) in subImage.strider.y.enumerated()
                            {                            
                                for (sx, dx):(Int, Int) in subImage.strider.x.enumerated()
                                {
                                    let si:Int = sx * bpp + subImage.shape.pitch   * sy, 
                                        di:Int = dx * bpp + properties.shape.pitch * dy
                                    
                                    for b:Int in 0 ..< bpp 
                                    {
                                        buffer[di + b] = self.data[base + si + b]
                                    }
                                }
                            }
                            
                            base += subImage.shape.byteCount
                        }
                    }
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
        
        static 
        func decodeIHDR(_ data:[UInt8]) throws -> Properties
        {
            guard data.count == 13 
            else 
            {
                throw ReadError.syntaxError(message: "png header length is \(data.count), expected 13")
            }
            
            let colorcode:UInt16 = data[8 ..< 10].load(bigEndian: UInt16.self, as: UInt16.self)
            guard let format:Properties.Format = Properties.Format.init(rawValue: colorcode)
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
                throw ReadError.syntaxError(message: "filter byte has value \(data[10]), expected 0")
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
            
            let width:Int  = data[0 ..< 4].load(bigEndian: UInt32.self, as: Int.self), 
                height:Int = data[4 ..< 8].load(bigEndian: UInt32.self, as: Int.self)
            
            return .init(size: (width, height), format: format, interlaced: interlaced)
        }
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
