#if os(macOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

@testable import PNG
do 
{
    try PNG.FileInterface.open(path: "tests/large/png/if red got the grammy.png") 
    {
        (file:inout PNG.FileInterface) in 
        
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
            
            print(chunk)
            switch chunk 
            {
                case .IHDR:
                    print(try PNG.Chunk.decodeIHDR(data))
                
                default:
                    break
            }
        }
    }
}

do 
{
    var verbose:Bool        = false
    var testSet:Set<String> = []

    for argument:String in CommandLine.arguments.dropFirst()
    {
        switch argument 
        {
            case "-v", "-verbose", "--verbose":
                verbose = true 
            
            default:
                testSet.insert(argument)
        }
    }
    
    exit(0)
}
