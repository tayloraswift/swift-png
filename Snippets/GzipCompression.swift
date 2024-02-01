import LZ77
import PNG

let path:String = "Snippets/GzipCompression/example"

guard
let gzipped:[UInt8] = (System.File.Source.open(path: "\(path).gz")
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

var inflator:Gzip.Inflator = .init()
try inflator.push(gzipped[...])

let text:String = .init(decoding: inflator.pull(), as: Unicode.UTF8.self)

print(text)
