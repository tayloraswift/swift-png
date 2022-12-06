import PNG 

struct Stream  
{
    private(set)
    var data:[UInt8], 
        position:Int, 
        available:Int 
}

extension Stream:PNG.Bytestream.Source
{
    init(_ data:[UInt8]) 
    {
        self.data       = data 
        self.position   = data.startIndex
        self.available  = data.startIndex
    }
    
    mutating 
    func read(count:Int) -> [UInt8]? 
    {
        guard self.position + count <= data.endIndex 
        else 
        {
            return nil 
        }
        guard self.position + count < self.available 
        else 
        {
            self.available += 4096
            return nil 
        }
        
        defer 
        {
            self.position += count 
        }
        
        return .init(self.data[self.position ..< self.position + count])
    }
    
    mutating 
    func reset(position:Int) 
    {
        precondition(self.data.indices ~= position)
        self.position = position
    }
}
extension Stream 
{
    init(path:String) 
    {
        guard let data:[UInt8]  = (System.File.Source.open(path: path) 
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
            fatalError("failed to open or read file '\(path)'")
        }

        self.init(data)
    }
}

func waitSignature(stream:inout Stream) throws  
{
    let position:Int = stream.position
    while true 
    {
        do 
        {
            return try stream.signature()
        }
        catch PNG.LexingError.truncatedSignature
        {
            stream.reset(position: position)
            continue 
        }
    }
}
func waitChunk(stream:inout Stream) throws -> (type:PNG.Chunk, data:[UInt8]) 
{
    let position:Int = stream.position
    while true 
    {
        do 
        {
            return try stream.chunk()
        }
        catch PNG.LexingError.truncatedChunkHeader, PNG.LexingError.truncatedChunkBody 
        {
            stream.reset(position: position)
            continue 
        }
    }
}

func decodeOnline(stream:inout Stream, overdraw:Bool, 
    capture:(PNG.Data.Rectangular) throws -> ()) throws 
    -> PNG.Data.Rectangular
{
    // lex PNG signature bytes
    try waitSignature(stream: &stream)
    // lex header chunk, and preceeding cgbi chunk, if present
    let (standard, header):(PNG.Standard, PNG.Header) = try
    {
        var chunk:(type:PNG.Chunk, data:[UInt8]) = try waitChunk(stream: &stream)
        let standard:PNG.Standard
        switch chunk.type
        {
        case .CgBI:
            standard    = .ios
            chunk       = try waitChunk(stream: &stream)
        default:
            standard    = .common
        }
        switch chunk.type 
        {
        case .IHDR:
            return (standard, try .init(parsing: chunk.data, standard: standard))
        default:
            fatalError("missing image header")
        }
    }()
    
    var chunk:(type:PNG.Chunk, data:[UInt8]) = try waitChunk(stream: &stream)
    
    var context:PNG.Context = try 
    {
        var palette:PNG.Palette?
        var background:PNG.Background?, 
            transparency:PNG.Transparency?
        var metadata:PNG.Metadata = .init()
        while true 
        {
            switch chunk.type 
            {
            case .PLTE:
                guard   palette             == nil, 
                        background          == nil, 
                        transparency        == nil
                else 
                {
                    fatalError("invalid chunk ordering")
                }
                palette = try .init(parsing: chunk.data, pixel: header.pixel)
            
            case .IDAT:
                guard let context:PNG.Context = PNG.Context.init(
                    standard:       standard, 
                    header:         header, 
                    palette:        palette, 
                    background:     background, 
                    transparency:   transparency, 
                    metadata:       metadata, 
                    uninitialized:  false)
                else 
                {
                    fatalError("missing palette")
                }
                return context
                
            case .IHDR, .IEND:
                fatalError("unexpected chunk")
            
            default:
                try metadata.push(ancillary: chunk, pixel: header.pixel, 
                    palette:        palette, 
                    background:     &background, 
                    transparency:   &transparency)
            }
            
            chunk = try waitChunk(stream: &stream)
        }
    }()
    
    while chunk.type == .IDAT  
    {
        try context.push(data: chunk.data, overdraw: overdraw)
        
        try capture(context.image)
        
        chunk = try waitChunk(stream: &stream)
    }
    
    while true 
    {
        try context.push(ancillary: chunk)
        guard chunk.type != .IEND 
        else 
        {
            return context.image 
        }
        chunk = try stream.chunk()
    }
} 

let path:String     = "examples/decode-online/example"

var stream:Stream   = .init(path: "\(path).png")

var counter:Int                 = 0
let image:PNG.Data.Rectangular  = try decodeOnline(stream: &stream, overdraw: false)
{
    (snapshot:PNG.Data.Rectangular) in 
    
    let _:[PNG.RGBA<UInt8>] = snapshot.unpack(as: PNG.RGBA<UInt8>.self)
    
    try snapshot.compress(path: "\(path)-\(counter).png")
    counter += 1
}

let layout:PNG.Layout = .init(format: image.layout.format, interlaced: true)
let progressive:PNG.Data.Rectangular = image.bindStorage(to: layout)

try progressive.compress(path: "\(path)-progressive.png", hint: 1 << 12)

stream                      = .init(path: "\(path)-progressive.png")
counter                     = 0
let _:PNG.Data.Rectangular  = try decodeOnline(stream: &stream, overdraw: false)
{
    (snapshot:PNG.Data.Rectangular) in 
    
    try snapshot.compress(path: "\(path)-progressive-\(counter).png")
    counter += 1
}

stream.reset(position: 0)

counter                     = 0
let _:PNG.Data.Rectangular  = try decodeOnline(stream: &stream, overdraw: true)
{
    (snapshot:PNG.Data.Rectangular) in 
    
    try snapshot.compress(path: "\(path)-progressive-overdrawn-\(counter).png")
    counter += 1
}
