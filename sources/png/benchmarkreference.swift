// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

#if os(macOS)
import func Darwin.clock
func clock() -> Int
{
    return .init(Darwin.clock())
}

#elseif os(Linux)
import func Glibc.clock
func clock() -> Int
{
    return Glibc.clock()
}

#else
    #error("unsupported or untested platform (please open an issue at https://github.com/kelvin13/png/issues)")
#endif

extension PNG 
{
    // internal benchmarking functions, to measure module boundary overhead
    public
    enum _Benchmarks
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
}
