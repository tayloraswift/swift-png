import LZ77
import PNG
//  snippet.ARCHIVE
let text:String = "hello barbie"

let archive:[UInt8] = Gzip.archive(
    bytes: [UInt8].init(text.utf8)[...],
    level: 9)
//  snippet.EXTRACT
let utf8:[UInt8] = try Gzip.extract(from: archive[...])
//  snippet.end
precondition(utf8.elementsEqual(text.utf8))

let path:String = "Sources/LZ77/docs.docc/GzipCompression"
//  snippet.EDGE_CASES
let _:Void? = System.File.Destination.open(path: "\(path)/empty.gz")
{
    $0.write(Gzip.archive(bytes: [][...], level: 10))
}
let _:Void? = System.File.Destination.open(path: "\(path)/single-byte.gz")
{
    $0.write(Gzip.archive(bytes: [0x0A][...], level: 10))
}
