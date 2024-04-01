import LZ77
import PNG

let path:String = "Sources/LZ77/docs.docc/GzipCompression/GzipCompression"

guard
let original:[UInt8] = (System.File.Source.open(path: "\(path).gz")
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
    fatalError("failed to open or read file '\(path).gz'")
}
//  snippet.INFLATE
var inflator:Gzip.Inflator = .init()
try inflator.push(original[...])

let utf8:[UInt8] = inflator.pull()
let text:String = .init(decoding: utf8, as: Unicode.UTF8.self)
//  snippet.end
print(text)

//  snippet.DEFLATE
var deflator:Gzip.Deflator = .init(level: 13, exponent: 15, hint: 128 << 10)
    deflator.push(utf8[...], last: true)

//  snippet.WRITE
let _:Void? = System.File.Destination.open(path: "\(path).txt.gz")
{
    while let part:[UInt8] = deflator.pull()
    {
        $0.write(part)
    }
}
