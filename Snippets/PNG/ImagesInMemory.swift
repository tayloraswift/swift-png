//  Our basic data type modeling a memory blob is incredibly simple; it consists of a Swift
//  array containing the data buffer, and a file position pointer in the form of an integer.
//  Here, we have namespaced it under the libary’s ``System`` namespace to parallel the built-in
//  file system APIs.

//  snippet.BLOB_TYPE
import PNG

//  snippet.hide
let path:String = "Sources/PNG/docs.docc/ImagesInMemory/ImagesInMemory"
//  snippet.show

extension System
{
    struct Blob
    {
        private(set)
        var data:[UInt8],
            position:Int
    }
}

//  snippet.BLOB_CONFORMANCE
extension System.Blob:PNG.BytestreamSource, PNG.BytestreamDestination
{
    init(_ data:[UInt8])
    {
        self.data       = data
        self.position   = data.startIndex
    }

    mutating
    func read(count:Int) -> [UInt8]?
    {
        guard self.position + count <= data.endIndex
        else
        {
            return nil
        }

        defer
        {
            self.position += count
        }

        return .init(self.data[self.position ..< self.position + count])
    }

    mutating
    func write(_ bytes:[UInt8]) -> Void?
    {
        self.data.append(contentsOf: bytes)
        return ()
    }
}

//  snippet.BLOB_BOOTSTRAP
guard
let data:[UInt8] = (System.File.Source.open(path: "\(path).png")
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
    fatalError("failed to open or read file '\(path).png'")
}

var blob:System.Blob = .init(data)
//  snippet.READ
let image:PNG.Image = try .decompress(stream: &blob)
let rgba:[PNG.RGBA<UInt8>] = image.unpack(as: PNG.RGBA<UInt8>.self)

//  snippet.end
guard
let _:Void = (System.File.Destination.open(path: "\(path).png.rgba")
{
    guard let _:Void = $0.write(rgba.flatMap{ [$0.r, $0.g, $0.b, $0.a] })
    else
    {
        fatalError("failed to write to file '\(path).png.rgba'")
    }
})
else
{
    fatalError("failed to open file '\(path).png.rgba'")
}

//  snippet.WRITE
blob = .init([])
try image.compress(stream: &blob, level: 13)

//  snippet.SAVE
guard
let _:Void = (System.File.Destination.open(path: "\(path).png.png")
{
    guard let _:Void = $0.write(blob.data)
    else
    {
        fatalError("failed to write to file '\(path).png.png'")
    }
})
else
{
    fatalError("failed to open file '\(path).png.png'")
}
