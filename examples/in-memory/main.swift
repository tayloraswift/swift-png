import PNG 

extension System 
{
    struct Blob 
    {
        private(set)
        var data:[UInt8], 
            position:Int 
    }
}

extension System.Blob:PNG.Bytestream.Source, PNG.Bytestream.Destination 
{
    init(_ data:[UInt8]) 
    {
        self.data       = data 
        self.position   = data.startIndex
    }
    
    mutating 
    func read(count:Int) -> [UInt8]? 
    {
        guard self.position + count <= data.endIndex 
        else 
        {
            return nil 
        }
        
        defer 
        {
            self.position += count 
        }
        
        return .init(self.data[self.position ..< self.position + count])
    }
    
    mutating 
    func write(_ bytes:[UInt8]) -> Void? 
    {
        self.data.append(contentsOf: bytes) 
        return ()
    }
}

let path:String         = "examples/in-memory/example"
guard let data:[UInt8]  = (System.File.Source.open(path: "\(path).png") 
{
    (source:inout System.File.Source) -> [UInt8]? in
    
    guard let count:Int = source.count
    else 
    {
        return nil 
    }
    return source.read(count: count)
} ?? nil)
else 
{
    fatalError("failed to open or read file '\(path).png'")
}

var blob:System.Blob = .init(data)
// read from blob 
let image:PNG.Data.Rectangular  = try .decompress(stream: &blob)
let rgba:[PNG.RGBA<UInt8>]      = image.unpack(as: PNG.RGBA<UInt8>.self)
guard let _:Void = (System.File.Destination.open(path: "\(path).png.rgba")
{
    guard let _:Void = $0.write(rgba.flatMap{ [$0.r, $0.g, $0.b, $0.a] })
    else 
    {
        fatalError("failed to write to file '\(path).png.rgba'")
    }
}) 
else
{
    fatalError("failed to open file '\(path).png.rgba'")
} 

// write to blob 
blob = .init([])
try image.compress(stream: &blob, level: 13)
guard let _:Void = (System.File.Destination.open(path: "\(path).png.png")
{
    guard let _:Void = $0.write(blob.data)
    else 
    {
        fatalError("failed to write to file '\(path).png.png'")
    }
}) 
else
{
    fatalError("failed to open file '\(path).png.png'")
} 
