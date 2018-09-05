@testable import PNG

fileprivate 
extension Array where Element == UInt8 
{    
    func load<T, U>(littleEndian:T.Type, as type:U.Type, at byte:Int) -> U 
        where T:FixedWidthInteger, U:BinaryInteger
    {
        return self[byte ..< byte + MemoryLayout<T>.size].load(littleEndian: T.self, as: U.self)
    }
}
fileprivate 
extension ArraySlice where Element == UInt8 
{
    func load<T, U>(littleEndian:T.Type, as type:U.Type) -> U 
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
            
            return U(T(littleEndian: value))
        }
    }
}

func decode(_ path:String) -> (PNG.Properties, [PNG.RGBA<UInt16>]) 
{
    guard let (properties, image):(PNG.Properties, [PNG.RGBA<UInt16>]) = PNG.FileInterface.open(path: path, body: 
    {
        (file:inout PNG.FileInterface) in 
        
        var decoder:PNG.Properties.Decoder?, 
            properties:PNG.Properties?, 
            rawData:[UInt8] = []
        
        do 
        {
            try PNG.forEachChunk(in: &file) 
            {
                (name:Math<UInt8>.V4, data:[UInt8]?) in 
                
                guard let chunk:PNG.Chunk = PNG.Chunk.init(name)
                else 
                {
                    let string:String = .init(decoding: [name.0, name.1, name.2, name.3], 
                                                    as: Unicode.ASCII.self)
                    throw PNG.ReadError.syntaxError(message: "chunk '\(string)' has invalid name")
                }
                    
                guard let data:[UInt8] = data 
                else 
                {
                    throw PNG.ReadError.corruptedChunk
                }
                
                switch chunk 
                {
                    case .IHDR:
                        let _properties:PNG.Properties = try .decodeIHDR(data)
                        decoder    = _properties.decoder()
                        properties = _properties
                    
                    case .IDAT:
                        try decoder?.forEachScanline(decodedFrom: data) 
                        {
                            rawData.append(contentsOf: $0)
                        }
                    
                    case .PLTE:
                        try properties?.decodePLTE(data)
                    
                    case .tRNS:
                        try properties?.decodetRNS(data)
                    
                    default:
                        break
                }
            }
        }
        catch 
        {
            fatalError(String(describing: error))
        }
        
        let uncompressed:PNG.Data.Uncompressed = .init(properties: properties!, data: rawData)
        return (uncompressed.properties, uncompressed.deinterlace().rgba16()!)
    })
    else 
    {
        fatalError("failed to open file")
    }
    
    return (properties, image)
}

func testDecode(_ name:String) -> String? 
{
    let pngPath:String  = "tests/unit/png/\(name).png", 
        rgbaPath:String = "tests/unit/rgba/\(name).png.rgba"
    let (properties, image):(PNG.Properties, [PNG.RGBA<UInt16>]) = decode(pngPath)
    let reference:[PNG.RGBA<UInt16>] = PNG.FileInterface.open(path: rgbaPath) 
        {
            let bytes:Int    = Math.vol(properties.shape.size) * MemoryLayout<PNG.RGBA<UInt16>>.stride, 
                data:[UInt8] = $0.read(count: bytes)!
            return (0 ..< Math.vol(properties.shape.size)).map 
            {
                let r:UInt16 = data.load(littleEndian: UInt16.self, as: UInt16.self, at: $0 << 3), 
                    g:UInt16 = data.load(littleEndian: UInt16.self, as: UInt16.self, at: $0 << 3 | 2), 
                    b:UInt16 = data.load(littleEndian: UInt16.self, as: UInt16.self, at: $0 << 3 | 4), 
                    a:UInt16 = data.load(littleEndian: UInt16.self, as: UInt16.self, at: $0 << 3 | 6)
                
                return .init(r, g, b, a)
            }
        }!
    return image == reference ? nil : "incorrect result"
}
