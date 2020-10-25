// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

#if os(macOS)
import func Darwin.clock
func clock() -> Int
{
    .init(Darwin.clock())
}

#elseif os(Linux)
import func Glibc.clock
func clock() -> Int
{
    Glibc.clock()
}

#else
    #warning("clock() function not imported for this platform, internal benchmarks not built (please open an issue at https://github.com/kelvin13/png/issues)")
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
        }
    }
}
extension __Entrypoint.Benchmark.Decode  
{
    public static
    func _structuredRGBA(_ path:String) -> Int
    {
        do 
        {
            let t1:Int = clock()
            guard let image:PNG.Data.Rectangular = try .decompress(path: path)
            else 
            {
                
                fatalError("could not open, read, or decode PNG file '\(path)'")
            }
            let _:[PNG.RGBA<UInt8>] = image.unpack(as: PNG.RGBA<UInt8>.self)
            let t:Int = clock() - t1
            return t
        }
        catch let error
        {
            print(error)
            return 0
        }
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
