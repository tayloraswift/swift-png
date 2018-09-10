import PNG

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

func testDecode(_ name:String) -> String? 
{
    let pngPath:String  = "tests/unit/png/\(name).png", 
        rgbaPath:String = "tests/unit/rgba/\(name).png.rgba"
    
    do 
    {
        guard let rectangular:PNG.Data.Rectangular = 
        (try PNG.FileInterface.open(path: pngPath) 
        {
            return try PNG.Data.Uncompressed.decode(from: &$0).deinterlace()
        })
        else 
        {
            return "failed to open file '\(pngPath)'"
        }
        
        guard let image:[PNG.RGBA<UInt16>] = rectangular.rgba16()
        else 
        {
            fatalError("unreachable: internal checks should have guaranteed palette validity")
        }
        
        guard let result:[PNG.RGBA<UInt16>]? = 
        (PNG.FileInterface.open(path: rgbaPath) 
        {
            let pixels:Int = Math.vol(rectangular.properties.size), 
                bytes:Int  = pixels * MemoryLayout<PNG.RGBA<UInt16>>.stride
                        
            guard let data:[UInt8] = $0.read(count: bytes) 
            else 
            {
                return nil  
            }
            
            return (0 ..< pixels).map 
            {
                let r:UInt16 = data.load(littleEndian: UInt16.self, as: UInt16.self, at: $0 << 3), 
                    g:UInt16 = data.load(littleEndian: UInt16.self, as: UInt16.self, at: $0 << 3 | 2), 
                    b:UInt16 = data.load(littleEndian: UInt16.self, as: UInt16.self, at: $0 << 3 | 4), 
                    a:UInt16 = data.load(littleEndian: UInt16.self, as: UInt16.self, at: $0 << 3 | 6)
                
                return .init(r, g, b, a)
            }
        })
        else 
        {
            return "failed to open file '\(rgbaPath)'"
        }
        
        guard let reference:[PNG.RGBA<UInt16>] = result 
        else 
        {
            return "failed to read file '\(rgbaPath)'"
        }
        
        for (i, pair):(Int, (PNG.RGBA<UInt16>, PNG.RGBA<UInt16>)) in 
            zip(image, reference).enumerated() 
        {
            guard pair.0 == pair.1 
            else 
            {
                return "pixel \(i) has value \(pair.0) (expected \(pair.1))"
            }
        }
        
        return nil
    }
    catch 
    {
        return "\(error)"
    }
}
