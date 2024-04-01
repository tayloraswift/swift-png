import LZ77
//  snippet.ARCHIVE
let text:String = "hello barbie"

let archive:[UInt8] = Gzip.archive(
    bytes: [UInt8].init(text.utf8)[...],
    level: 9)
//  snippet.EXTRACT
let utf8:[UInt8] = try Gzip.extract(from: archive[...])
//  snippet.end
precondition(utf8.elementsEqual(text.utf8))
