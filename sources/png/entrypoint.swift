// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

#if INTERNAL_BENCHMARKS

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

public 
enum __Entrypoint 
{
}

#if os(macOS) || os(Linux)
// internal benchmarking functions, to measure module boundary overhead
extension __Entrypoint 
{
    public 
    enum Benchmark 
    {
        public 
        enum Dictionary 
        {
        }
        public 
        enum Decode 
        {
            struct Blob
            {
                private
                let buffer:[UInt8] 
                private(set)
                var count:Int 
            }
        }
        public 
        enum Encode 
        {
            struct Blob
            {
                private(set) 
                var buffer:[UInt8] = []
            }
        }
    }
}
extension __Entrypoint.Benchmark.Decode.Blob:PNG.Bytestream.Source
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
extension __Entrypoint.Benchmark.Encode.Blob:PNG.Bytestream.Destination
{
    mutating 
    func write(_ data:[UInt8]) -> Void?
    {
        self.buffer.append(contentsOf: data) 
        return ()
    }
}
extension __Entrypoint.Benchmark.Decode
{
    public static
    func rgba8(path:String, trials:Int) -> [(time:Int, hash:Int)]
    {
        guard var blob:Blob = .load(path: path)
        else 
        {
            fatalError("could not read file '\(path)'")
        }
        
        return (0 ..< trials).map 
        {
            _ in 
            // sleep for 0.1s between runs to emulate a “cold” start
            nanosleep([timespec.init(tv_sec: 0, tv_nsec: 100_000_000)], nil)
            blob.reload()
            
            do 
            {
                let start:Int = clock()
                
                let image:PNG.Data.Rectangular  = try .decompress(stream: &blob)
                let pixels:[PNG.RGBA<UInt8>]    = image.unpack(as: PNG.RGBA<UInt8>.self)
                
                let stop:Int = clock()
                return (stop - start, .init(pixels.last?.r ?? 0))
            }
            catch let error
            {
                fatalError("\(error)")
            }
        }
    }
}
extension __Entrypoint.Benchmark.Encode
{
    public static
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
extension __Entrypoint.Benchmark.Dictionary 
{
    public static 
    func updateRemove(count:Int = 1 << 22) -> (baseline:Int, accelerated:Int)
    {
        let data:[UInt32] = (0 ..< count).map{ _ in .random(in: .min ... .max) }
        
        let accelerated:Int = 
        {
            (data:[UInt32]) -> Int in 
            
            let t:(Int, Int)
            
            t.0 = clock()
            let dictionary:General.Dictionary = .init(exponent: 15)
            for (i, key):(Int, UInt32) in data.enumerated() 
            {
                let value:UInt16 = .init(i & 0x7f_ff)
                dictionary.update(key: key, value: value)
                dictionary.remove(key: data[(i - 0x80_00) & (1 << 22 - 1)], value: value)
            }
            t.1 = clock()
            
            return t.1 - t.0
        }(data)
        
        let baseline:Int = 
        {
            (data:[UInt32]) -> Int in 
            
            let t:(Int, Int)
            
            t.0 = clock()
            var dictionary:[UInt32: UInt16] = [:]
            dictionary.reserveCapacity(1 << 15)
            
            for (i, key):(Int, UInt32) in data.enumerated() 
            {
                let value:UInt16 = .init(i & 0x7f_ff)
                dictionary.updateValue(value, forKey: key)
                
                let x:UInt32 = data[(i - 0x80_00) & (1 << 22 - 1)]
                if dictionary[x] == value 
                {
                    dictionary[x] = nil 
                }
            }
            t.1 = clock()
            
            return t.1 - t.0
        }(data)
        
        return (baseline: baseline, accelerated: accelerated)
    } 
}

#endif 
#endif 
