//

//  snippet.LOAD_EXAMPLE
import PNG

let path:String = "Sources/PNG/docs.docc/ImageMetadata/ImageMetadata"

guard
var image:PNG.Image = try .decompress(path: "\(path).png")
else
{
    fatalError("failed to open file '\(path).png'")
}

//  snippet.INSPECT_CHUNKS
if  let time:PNG.TimeModified = image.metadata.time
{
    print(time)
}
if  let gamma:PNG.Gamma = image.metadata.gamma
{
    print(gamma)
}
if  let physicalDimensions:PNG.PhysicalDimensions = image.metadata.physicalDimensions
{
    print(physicalDimensions)
}

//  snippet.PRINT_CHUNKS
print(image.metadata)

//  snippet.MODIFY_CHUNKS
image.metadata.time = .init(year: 1992, month: 8, day: 3, hour: 0, minute: 0, second: 0)

//  snippet.SAVE_EXAMPLE
try image.compress(path: "\(path)-newtime.png")

if  let image:PNG.Image = try .decompress(path: "\(path)-newtime.png"),
    let time:PNG.TimeModified = image.metadata.time ?? nil
{
    print(time)
}
