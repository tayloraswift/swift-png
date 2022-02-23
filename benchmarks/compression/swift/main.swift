// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
import PNG

#if os(macOS)
import func Darwin.nanosleep
import struct Darwin.timespec
import func Darwin.clock
import var Darwin.CLOCKS_PER_SEC
func clock() -> Int
{
    .init(Darwin.clock())
}

#elseif os(Linux)
import func Glibc.nanosleep
import struct Glibc.timespec
import func Glibc.clock
import var Glibc.CLOCKS_PER_SEC
func clock() -> Int
{
    Glibc.clock()
}

#else
    #warning("clock() function not imported for this platform, internal benchmarks not built (please open an issue at https://github.com/kelvin13/swift-png/issues)")
#endif

#if os(macOS) || os(Linux)

// internal benchmarking functions, to measure module boundary overhead
enum Benchmark 
{
    enum Encode 
    {
        struct Blob
        {
            private(set) 
            var buffer:[UInt8] = []
        }
    }
}
extension Benchmark.Encode.Blob:PNG.Bytestream.Destination 
{
    mutating 
    func write(_ data:[UInt8]) -> Void?
    {
        self.buffer.append(contentsOf: data) 
        return ()
    }
}
extension Benchmark.Encode
{
    static
    func rgba8(level:Int, path:String, trials:Int) -> ([(time:Int, hash:Int)], Int)
    {
        guard let image:PNG.Data.Rectangular = try? .decompress(path: path)
        else 
        {
            fatalError("failed to decode test image '\(path)'")
        }
        
        let results:[(time:Int, size:Int, hash:Int)] = (0 ..< trials).map 
        {
            _ in 
            // sleep for 0.1s between runs to emulate a “cold” start
            nanosleep([timespec.init(tv_sec: 0, tv_nsec: 100_000_000)], nil)
            var blob:Blob   = .init()
            do 
            {
                let start:Int = clock()
                
                try image.compress(stream: &blob, level: level)
                
                let stop:Int = clock()
                return (stop - start, blob.buffer.count, .init(blob.buffer.last ?? 0))
            }
            catch let error
            {
                fatalError("\(error)")
            }
        }
        
        return (results.map{ (time: $0.time, hash: $0.hash) }, results.map(\.size).min() ?? 0)
    }
}

func main() throws
{
    guard   CommandLine.arguments.count == 4, 
            let level:Int   = Int.init(CommandLine.arguments[1]),
            let trials:Int  = Int.init(CommandLine.arguments[3])
            
    else 
    {
        fatalError("usage: \(CommandLine.arguments.first ?? "") <compression-level:0 ... 9> <image> <trials>")
    }
    
    let path:String = CommandLine.arguments[2]
    
    guard 0 ... 13 ~= level
    else 
    {
        fatalError("compression level must be an integer from 0 to 13")
    }
    
    #if INTERNAL_BENCHMARKS 
    let (results, size):([(time:Int, hash:Int)], Int) = 
        __Entrypoint.Benchmark.Encode.rgba8(level: level, path: path, trials: trials)
    #else 
    let (results, size):([(time:Int, hash:Int)], Int) = 
                     Benchmark.Encode.rgba8(level: level, path: path, trials: trials)
    #endif
    
    let string:String = results.map
    { 
        "\(1000.0 * .init($0.time) / .init(CLOCKS_PER_SEC))" 
    }.joined(separator: " ")
    
    print("\(string), \(size)")
}

try main()

#endif
