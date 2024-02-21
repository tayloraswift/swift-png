import LZ77

let text:String = """
    __,
    (           o  /) _/_
    `.  , , , ,  //  /
(___)(_(_/_(_ //_ (__
                /)
            (/
"""

var deflator:LZ77.Deflator = .init(format: .zlib, level: 7, hint: 1_00)
let utf8:[UInt8] = .init(text.utf8)

print("Uncompressed size: \(utf8.count) bytes")

deflator.push(utf8[...], last: false)
deflator.push(utf8[...], last: true)

var data:[UInt8] = []
while let part:[UInt8] = deflator.pull()
{
    data += part
}

print("Compressed size: \(data.count) bytes")

var inflator:LZ77.Inflator = .init()
try inflator.push(data[...])

let output:[UInt8] = inflator.pull()

precondition(output == utf8 + utf8, "Round-trip failed!")
