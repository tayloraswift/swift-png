import PNG4

#if os(macOS)
import func Darwin.clock
import var Darwin.CLOCKS_PER_SEC
func clock() -> Int
{
    return .init(Darwin.clock())
}
#elseif os(Linux)
import func Glibc.clock
import var Glibc.CLOCKS_PER_SEC
func clock() -> Int
{
    return Glibc.clock()
}
#endif

struct Blob:PNG.Bytestream.Destination 
{
    private(set) 
    var buffer:[UInt8] = []
    
    var count:Int 
    {
        self.buffer.count
    }
    
    mutating 
    func write(_ data:[UInt8]) -> Void?
    {
        self.buffer.append(contentsOf: data) 
        return ()
    }
}

func main() throws
{
    guard CommandLine.arguments.count == 4 
    else 
    {
        fatalError("wrong number of arguments")
    }
    
    let path:String = CommandLine.arguments[1], 
        name:String = CommandLine.arguments[2]
    guard let level:Int = Int.init(CommandLine.arguments[3]), 0 ... 9 ~= level
    else 
    {
        fatalError("compression level must be an integer from 0 to 9")
    }
    
    guard let image:PNG.Data.Rectangular = try .decompress(path: path)
    else 
    {
        fatalError("failed to decode test image '\(path)'")
    }
    
    let start:Int   = clock()
    var blob:Blob   = .init()
    try image.compress(stream: &blob, level: level)
    let stop:Int    = clock()
    print("\(level) \(1000.0 * .init(stop - start) / .init(CLOCKS_PER_SEC)) \(blob.count) \(name)")
}

try main()
