// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
import PNG

#if os(macOS)
import func Darwin.clock
import var Darwin.CLOCKS_PER_SEC
func clock() -> Int
{
    .init(Darwin.clock())
}

#elseif os(Linux)
import func Glibc.clock
import var Glibc.CLOCKS_PER_SEC
func clock() -> Int
{
    Glibc.clock()
}

#else
    #warning("clock() function not imported for this platform, internal benchmarks not built (please open an issue at https://github.com/kelvin13/png/issues)")
#endif

#if os(macOS) || os(Linux)

struct Blob:PNG.Bytestream.Source 
{
    private 
    let buffer:[UInt8] 
    private(set)
    var count:Int 
    
    static 
    func load(path:String) -> Self? 
    {
        System.File.Source.open(path: path) 
        {
            (file:inout System.File.Source) -> Self? in 
            guard   let count:Int       = file.count, 
                    let buffer:[UInt8]  = file.read(count: count)
            else 
            {
                return nil 
            }
            return .init(buffer: buffer, count: count)
        } ?? nil 
    }
    
    mutating 
    func read(count:Int) -> [UInt8]?
    {
        guard count <= self.count 
        else 
        {
            return nil 
        }
        let data:[UInt8] = .init(self.buffer.suffix(self.count).prefix(count))
        self.count      -= count 
        return data
    }
    
    mutating 
    func reload() 
    {
        self.count = self.buffer.count
    }
}

// internal benchmarking functions, to measure module boundary overhead
enum Benchmark 
{
    enum Decode 
    {
    }
    
    struct Blob:PNG.Bytestream.Source 
    {
        private 
        let buffer:[UInt8] 
        private(set)
        var count:Int 
    }
}
extension Benchmark.Blob 
{
    static 
    func load(path:String) -> Self? 
    {
        System.File.Source.open(path: path) 
        {
            (file:inout System.File.Source) -> Self? in 
            guard   let count:Int       = file.count, 
                    let buffer:[UInt8]  = file.read(count: count)
            else 
            {
                return nil 
            }
            return .init(buffer: buffer, count: count)
        } ?? nil 
    }
    
    mutating 
    func read(count:Int) -> [UInt8]?
    {
        guard count <= self.count 
        else 
        {
            return nil 
        }
        let data:[UInt8] = .init(self.buffer.suffix(self.count).prefix(count))
        self.count      -= count 
        return data
    }
    
    mutating 
    func reload() 
    {
        self.count = self.buffer.count
    }
}
extension Benchmark.Decode
{
    static
    func structuredRGBA(path:String) -> (time:Int, size:Int)
    {
        guard var blob:Benchmark.Blob = .load(path: path)
        else 
        {
            fatalError("could not read file '\(path)'")
        }
        
        let size:Int = blob.count
        
        do 
        {
            let start:Int = clock()
            
            let image:PNG.Data.Rectangular  = try .decompress(stream: &blob)
            let _:[PNG.RGBA<UInt8>]         = image.unpack(as: PNG.RGBA<UInt8>.self)
            
            let stop:Int = clock()
            return (stop - start, size)
        }
        catch let error
        {
            fatalError("\(error)")
        }
    }
}

func main() throws
{
    guard CommandLine.arguments.count == 3
    else 
    {
        fatalError("wrong number of arguments")
    }
    
    let path:String = CommandLine.arguments[1], 
        name:String = CommandLine.arguments[2]
    
    let measured:(time:Int, size:Int) = Benchmark.Decode.structuredRGBA(path: path)
    
    print("\(1000.0 * .init(measured.time) / .init(CLOCKS_PER_SEC)) \(measured.size) \(name)")
    
    #if INTERNAL_BENCHMARKS
    
    let measured2:(time:Int, size:Int, hash:Int) = __Entrypoint.Benchmark.Decode.structuredRGBA(path: path)
    
    print("\(1000.0 * .init(measured2.time) / .init(CLOCKS_PER_SEC)) \(measured2.size) \(name)")
    
    #endif
}

try main()

#endif
