/// An abstract data source. To provide a custom data source to the library, conform
/// your type to this protocol by implementing the `read(count:)` method.
protocol DataSource
{
    /// Read the specified number of bytes from this data source.
    /// - Parameters:
    ///     - count: The number of bytes to read.
    /// - Returns: An array of size `count`, if `count` bytes could be read, and
    ///     `nil` otherwise.
    mutating
    func read(count:Int) -> [UInt8]?
}
/// An abstract data destination. To specify a custom data destination for the library,
/// conform your type to this protocol by implementing the `write(_:)` method.
protocol DataDestination
{
    /// Write the given data buffer to this data destination.
    /// - Parameters:
    ///     - buffer: The data to write.
    /// - Returns: `()` on success, and `nil` otherwise.
    mutating
    func write(_ buffer:[UInt8]) -> Void?
}

/// A fixed-width integer type which can be packed in groups of four within another
/// integer type. For example, four `UInt8`s may be packed into a single `UInt32`.
protocol FusedVector4Element:FixedWidthInteger & UnsignedInteger
{
    /// A fixed-width integer type which can hold four instances of `Self`.
    associatedtype FusedVector4:FixedWidthInteger & UnsignedInteger
}
extension UInt8:FusedVector4Element
{
    typealias FusedVector4 = UInt32
}
extension UInt16:FusedVector4Element
{
    typealias FusedVector4 = UInt64
}


extension PNG.RGBA where Component:FusedVector4Element
{
    /// The components of this pixel value packed into a single unsigned integer in
    /// ARGB order, with the alpha component in the high bits.
    /// 
    /// *Inlinable*.
    var argb:Component.FusedVector4
}

/// Encode and decode image data in the PNG format.
enum PNG
{
    /// A two-component color value, with components stored in the grayscale-alpha
    /// color model. This structure has fixed layout, with the value component first,
    /// then alpha. Buffers containing instances of this type may be safely reinterpreted
    /// as flat buffers containing interleaved components.
    @frozen
    struct VA<Component> where Component:FixedWidthInteger & UnsignedInteger
    {
        /// The value component of this color.
        var v:Component
        /// The alpha component of this color.
        var a:Component

        /// Creates an opaque grayscale color with the value component set to the
        /// given value sample, and the alpha component set to `Component.max`.
        /// 
        /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64,
        ///     and `UInt`.
        /// - Parameters:
        ///     - value: The value to initialize the value component to.
        init(_ value:Component)

        /// Creates a grayscale color with the value component set to the given
        /// value sample, and the alpha component set to the given alpha sample.
        /// 
        /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64,
        ///     and `UInt`.
        /// - Parameters:
        ///     - value: The value to initialize the value component to.
        ///     - alpha: The value to initialize the alpha component to.
        init(_ value:Component, _ alpha:Component)

        /// The color obtained by premultiplying the value component of this color
        /// with its alpha component. The resulting component values are accurate
        /// to within 1 `Component` unit.
        /// 
        /// *Inlinable*.
        var premultiplied:VA<Component>
    }

    /// A four-component color value, with components stored in the RGBA color model.
    /// This structure has fixed layout, with the red component first, then green,
    /// then blue, then alpha. Buffers containing instances of this type may be
    /// safely reinterpreted as flat buffers containing interleaved components.
    @frozen
    struct RGBA<Component> where Component:FixedWidthInteger & UnsignedInteger
    {
        /// The red component of this color.
        var r:Component
        /// The green component of this color.
        var g:Component
        /// The blue component of this color.
        var b:Component
        /// The alpha component of this color.
        var a:Component

        /// Creates an opaque grayscale color with all color components set to the given
        /// value sample, and the alpha component set to `Component.max`.
        /// 
        /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64,
        ///     and `UInt`.
        /// - Parameters:
        ///     - value: The value to initialize all color components to.
        init(_ value:Component)

        /// Creates a grayscale color with all color components set to the given
        /// value sample, and the alpha component set to the given alpha sample.
        /// 
        /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64,
        ///     and `UInt`.
        /// - Parameters:
        ///     - value: The value to initialize all color components to.
        ///     - alpha: The value to initialize the alpha component to.
        init(_ value:Component, _ alpha:Component)

        /// Creates an opaque color with the given color samples, and the alpha
        /// component set to `Component.max`.
        /// 
        /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64,
        ///     and `UInt`.
        /// - Parameters:
        ///     - red: The value to initialize the red component to.
        ///     - green: The value to initialize the green component to.
        ///     - blue: The value to initialize the blue component to.
        init(_ red:Component, _ green:Component, _ blue:Component)

        /// Creates an opaque color with the given color and alpha samples.
        /// 
        /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64,
        ///     and `UInt`.
        /// - Parameters:
        ///     - red: The value to initialize the red component to.
        ///     - green: The value to initialize the green component to.
        ///     - blue: The value to initialize the blue component to.
        ///     - alpha: The value to initialize the alpha component to.
        init(_ red:Component, _ green:Component, _ blue:Component, _ alpha:Component)

        /// The color obtained by premultiplying the red, green, and blue components
        /// of this color with its alpha component. The resulting component values
        /// are accurate to within 1 `Component` unit.
        /// 
        /// *Inlinable*.
        var premultiplied:RGBA<Component>
        
        /// The red, and alpha components of this color, stored as a grayscale-alpha
        /// color.
        /// 
        /// *Inlinable*.
        var va:VA<Component>
    }

    /// A namespace for file IO functionality.
    enum File
    {
        enum Error:Swift.Error
        {
            /// A file could not be opened.
            ///
            /// This error is not thrown by any `File` methods, but is used by users
            /// of these APIs.
            case couldNotOpen
        }

        /// Read data from files on disk.
        struct Source:DataSource
        {
            /// Calls a closure with an interface for reading from the specified file.
            /// 
            /// This method automatically closes the file when its function argument returns.
            /// - Parameters:
            ///     - path: A path to the file to open.
            ///     - body: A closure with a `Source` parameter from which data in
            ///         the specified file can be read. This interface is only valid
            ///         for the duration of the method’s execution. The closure is
            ///         only executed if the specified file could be successfully
            ///         opened, otherwise `nil` is returned. If `body` has a return
            ///         value and the specified file could be opened, its return
            ///         value is returned as the return value of the `open(path:body:)`
            ///         method.
            /// - Returns: `nil` if the specified file could not be opened, or the
            ///     return value of the function argument otherwise.
            static
            func open<Result>(path:String, _ body:(inout Source) throws -> Result)
                rethrows -> Result?
            
            /// Read the specified number of bytes from this file interface.
            /// 
            /// This method only returns an array if the exact number of bytes
            /// specified could be read. This method advances the file pointer.
            /// 
            /// - Parameters:
            ///     - capacity: The number of bytes to read.
            /// - Returns: An array containing the read data, or `nil` if the specified
            ///     number of bytes could not be read.
            func read(count capacity:Int) -> [UInt8]?
        }

        /// Write data to files on disk.
        struct Destination:DataDestination
        {
            /// Calls a closure with an interface for writing to the specified file.
            /// 
            /// This method automatically closes the file when its function argument returns.
            /// - Parameters:
            ///     - path: A path to the file to open.
            ///     - body: A closure with a `Destination` parameter representing
            ///         the specified file to which data can be written to. This
            ///         interface is only valid for the duration of the method’s
            ///         execution. The closure is only executed if the specified
            ///         file could be successfully opened, otherwise `nil` is returned.
            ///         If `body` has a return value and the specified file could
            ///         be opened, its return value is returned as the return value
            ///         of the `open(path:body:)` method.
            /// - Returns: `nil` if the specified file could not be opened, or the
            ///     return value of the function argument otherwise.
            static
            func open<Result>(path:String, body:(inout Destination) throws -> Result)
                rethrows -> Result?

            /// Write the bytes in the given array to this file interface.
            /// 
            /// This method only returns `()` if the entire array argument could
            /// be written. This method advances the file pointer.
            /// 
            /// - Parameters:
            ///     - buffer: The data to write.
            /// - Returns: `()` if the entire array argument could be written, or
            ///     `nil` otherwise.
            func write(_ buffer:[UInt8]) -> Void?
        }
    }

    /// The global properties of a PNG image.
    struct Properties
    {
        /// A pixel format used to encode the color values of a PNG.
        /// 
        /// Pixel formats consist of a color format, and a color depth.
        /// 
        /// Color formats can have multiple components, one for each independent
        /// dimension pixel values encoded in this format have. A grayscale format,
        /// for example, has one component (value), while an RGBA format has four
        /// (red, green, blue, alpha).
        /// 
        /// Components are separate from channels, which are the independent values
        /// needed to *encode*a pixel value in a PNG image. An indexed pixel format,
        /// for example, has only one channel — a scalar index into a palette table —
        /// but has three components, as the entries in the palette table encode
        /// red, green, and blue components.
        /// 
        /// Color depth refers to the number of bits of precision used to encode
        /// each channel.
        /// 
        /// Not all combinations of color formats and color depths are allowed.
        /// 
        /// | *depth* |  indexed   |   grayscale   | grayscale-alpha |   RGB   |   RGBA   |
        /// | ------- | ---------- | ------------- | --------------- | ------- | -------- |
        /// |    1    | `indexed1` | `v1`          |
        /// |    2    | `indexed2` | `v2`          |
        /// |    4    | `indexed4` | `v4`          |
        /// |    8    | `indexed8` | `v8`          | `va8`           | `rgb8`  | `rgba8`  |
        /// |    16   |            | `v16`         | `va16`          | `rgb16` | `rgba16` |
        enum Format
        {
            case    v1,
                    v2,
                    v4,
                    v8,
                    v16,
                    rgb8(_ palette:[RGBA<UInt8>]?),
                    rgb16(_ palette:[RGBA<UInt8>]?),
                    indexed1(_ palette:[RGBA<UInt8>]),
                    indexed2(_ palette:[RGBA<UInt8>]),
                    indexed4(_ palette:[RGBA<UInt8>]),
                    indexed8(_ palette:[RGBA<UInt8>]),
                    va8,
                    va16,
                    rgba8(_ palette:[RGBA<UInt8>]?),
                    rgba16(_ palette:[RGBA<UInt8>]?)
            enum Code:UInt16
            {
                case    v1          = 0x01_00,
                        v2          = 0x02_00,
                        v4          = 0x04_00,
                        v8          = 0x08_00,
                        v16         = 0x10_00,
                        rgb8        = 0x08_02,
                        rgb16       = 0x10_02,
                        indexed1    = 0x01_03,
                        indexed2    = 0x02_03,
                        indexed4    = 0x04_03,
                        indexed8    = 0x08_03,
                        va8         = 0x08_04,
                        va16        = 0x10_04,
                        rgba8       = 0x08_06,
                        rgba16      = 0x10_06

                /// The bit depth of each channel of this pixel format.
                var depth:Int

                /// A boolean value indicating if this pixel format has indexed color.
                /// 
                /// `true` if `self` is `indexed1`, `indexed2`, `indexed4`, or `indexed8`.
                /// `false` otherwise.
                var isIndexed:Bool

                /// A boolean value indicating if this pixel format has at least three
                /// color components.
                /// 
                /// `true` if `self` is `indexed1`, `indexed2`, `indexed4`, `indexed8`,
                /// `rgb8`, `rgb16`, `rgba8`, or `rgba16`. `false` otherwise.
                var hasColor:Bool

                /// A boolean value indicating if this pixel format has an alpha channel.
                /// 
                /// `true` if `self` is `va8`, `va16`, `rgba8`, or
                /// `rgba16`. `false` otherwise.
                var hasAlpha:Bool

                /// The number of channels encoded by this pixel format.
                var channels:Int

                /// The number of components represented by this pixel format.
                var components:Int
            }
            
            var code:Code

            /// The palette associated with this color format, if applicable.
            var palette:[RGBA<UInt8>]?
        }

        struct Header
        {
            let size:(x:Int, y:Int)
            let code:Format.Code
            let interlaced:Bool

            /// Decodes the data of an IHDR chunk as a `Properties` record.
            /// 
            /// - Parameters:
            ///     - data: IHDR chunk data.
            /// - Returns: A `Properties` object containing the information encoded by
            ///     the given IHDR chunk.
            /// - Throws:
            ///     - DecodingError.invalidChunk: If any of the IHDR chunk fields contain
            ///         an invalid value.
            static
            func decodeIHDR(_ data:[UInt8]) throws -> Header

            /// Decodes the data of a PLTE chunk, validates, and returns it as an
            /// array of `PNG.RGBA<UInt8>` entries.
            /// 
            /// - Parameters:
            ///     - data: PLTE chunk data. Must not contain more entries than this
            ///         PNG’s color depth can uniquely encode.
            /// - Throws:
            ///     - DecodingError.invalidChunk: If the given palette data does not contain
            ///         a whole number of palette entries, or if it contains more than
            ///         `1 << format.depth` entries
            ///     - DecodingError.unexpectedChunk: If this PNG does not have
            ///         a three-color format.
            func decodePLTE(_ data:[UInt8]) throws -> [RGBA<UInt8>]
            
            /// Decodes the data of a tRNS chunk, validates, and modifies the given
            /// palette table.
            /// 
            /// This method should only be called if the PNG has an indexed pixel format.
            /// 
            /// - Parameters:
            ///     - data: tRNS chunk data. It must not contain more transparency
            ///         values than the PNG’s color depth can uniquely encode.
            /// - Throws:
            ///     - DecodingError.invalidChunk: If the given transparency data
            ///         contains more than `palette.count` trasparency values.
            ///     - DecodingError.unexpectedChunk: If the PNG does not have an
            ///         indexed color format.
            func decodetRNS(_ data:[UInt8], palette:inout [RGBA<UInt8>]) throws
            
            /// Decodes the data of a tRNS chunk, validates, and returns a chroma key.
            /// 
            /// This method should only be called if the PNG has an RGB or grayscale
            /// pixel format.
            /// 
            /// - Parameters:
            ///     - data: tRNS chunk data. If this PNG has a grayscale pixel format,
            ///         it must contain one value sample. If this PNG has an RGB pixel
            ///         format, it must contain three samples, red, green, and blue.
            /// - Throws:
            ///     - DecodingError.invalidChunk: If the given transparency data does not
            ///         contain the correct number of samples.
            ///     - DecodingError.unexpectedChunk: If the PNG does not have an
            ///         opaque color format.
            func decodetRNS(_ data:[UInt8]) throws -> RGBA<UInt16>
        }

        /// The pixel format of this PNG image, and its associated color palette,
        /// if applicable.
        let format:Format

        /// The chroma key of this PNG image, if it has one.
        /// 
        /// The alpha component of this property is ignored by the library.
        var chromaKey:RGBA<UInt16>?

        /// A boolean value indicating if this PNG image uses an interlacing algorithm.
        var interlaced:Bool
        
        /// The pixel dimensions of this PNG image.
        var size:(x:Int, y:Int)
        
        /// Creates a PNG `Properties` record with the given properties.
        ///
        /// - Parameters:
        ///     - size: A pair of pixel dimensions.
        ///     - format: A pixel format.
        ///     - interlaced: A boolean value indicating if an interlacing algorithm
        ///         will be used. The default is `false`.
        ///     - chromaKey: A chroma key, or `nil`. The default is `nil`.
        init(size:(x:Int, y:Int), format:Format, interlaced:Bool = false,
            chromaKey:RGBA<UInt16>? = nil)

        /// Initializes and returns a PNG `Decoder`.
        /// - Returns: An image `Decoder` in its initial state.
        func decoder() throws -> Decoder

        /// Initializes and returns a PNG `Encoder`.
        /// - Parameters:
        ///     - level: The compression level the returned `Encoder` will use.
        ///         Must be in the range `0 ... 9`, where 0 is no compression, and
        ///         9 is the highest possible amount of compression.
        /// - Returns: An image `Encoder` in its initial state.
        func encoder(level:Int) throws -> Encoder
        
        /// A low level API for receiving and processing decompressed and decoded
        /// PNG image data at the scanline level.
        struct Decoder
        {
            /// Calls the given closure for each complete scanline decoded from
            /// the given compressed image data, passing the decoded contents of
            /// the scanline to the closure.
            /// 
            /// Individual data blocks can produce incomplete scanlines. These
            /// scanlines are stored and will be completed by subsequent data blocks,
            /// when they will be passed as full scanlines to the closures given
            /// in the later `forEachScanline(decodedFrom:_:)` calls.
            /// - Parameters:
            ///     - data: Compressed image data.
            ///     - body: A closure which takes as an argument a decoded scanline.
            /// - Returns: `true` if this `Decoder`’s LZ77 stream expects more input
            ///     data, and `false` otherwise.
            /// 
            /// - Warning: Do not call this method again on the same instance after
            ///     it has returned `false`. Doing so will result in undefined behavior.
            mutating
            func forEachScanline(decodedFrom data:[UInt8], _ body:(ArraySlice<UInt8>) throws -> ())
                throws -> Bool
        }

        /// A low level API for filtering and compressing PNG image data at the
        /// scanline level.
        struct Encoder
        {
            /// Filters and compresses scanlines returned by the given closure,
            /// appending the compressed data to the given data buffer.
            /// 
            /// *Specialized* for `RAC` types `[UInt8]`, `ArraySlice<UInt8>`, `UnsafeBufferPointer<UInt8>`,
            /// `Slice<UnsafeBufferPointer<UInt8>>`, and `Slice<UnsafeMutableBufferPointer<UInt8>>`.
            /// 
            /// - Parameters:
            ///     - data: A data buffer to append compressed scanline data to.
            ///     - capacity: The maximum size `data` is allowed to reach before
            ///         this method will stop outputting data to it.
            ///     - generator: A closure which, when called repeatedly, returns
            ///         scanlines to filter and compress, and `nil` when there
            ///         are no more scanlines to encode.
            /// 
            /// - Returns: `true` if `data.count` was filled to the specified capacity,
            ///     or if `generator` returned `nil`. `false` if this `Encoder`
            ///     is finished encoding data. Once this method returns `false`,
            ///     it should not be called again on the same instance.
            /// - Throws: `EncodingError.bufferCount`, if `generator` returns a scanline
            ///     that does not have the expected size.
            mutating
            func consolidate<RAC>(extending data:inout [UInt8], capacity:Int,
                scanlinesFrom generator:() -> RAC?) throws -> Bool
                where RAC:RandomAccessCollection, RAC.Element == UInt8
        }

        /// Encodes the header fields of this `Properties` record as the chunk data
        /// of an IHDR chunk.
        /// 
        /// - Returns: An array containing IHDR chunk data. The chunk header, length,
        ///     and crc32 tail are not included.
        func encodeIHDR() -> [UInt8]

        /// Encodes this PNG’s palette as the chunk data of a PLTE chunk, if it
        /// has one.
        /// 
        /// This method always returns valid PLTE chunk data. If this `Properties`
        /// record has more palette entries than can be encoded with its color depth,
        /// only the first `1 << format.depth` entries are encoded. This method
        /// does not remove palette entries from this metatada record itself.
        /// 
        /// - Returns: An array containing PLTE chunk data, or `nil` if this PNG
        ///     does not have a palette. The chunk header, length,
        ///     and crc32 tail are not included.
        func encodePLTE() -> [UInt8]?

        /// Encodes this PNG’s transparency information as the chunk data of a tRNS
        /// chunk, if it has any.
        /// 
        /// This method always returns valid tRNS chunk data. If this PNG has an
        /// indexed pixel format, and this `Properties` record has more palette entries
        /// than can be encoded with its color depth, then only the first `1 << format.depth`
        /// transparency values are encoded. This method does not remove palette
        /// entries from this `Properties` record itself.
        /// 
        /// - Returns: An array containing tRNS chunk data, or `nil` if this PNG
        ///     does not have an transparency information. The chunk header, length,
        ///     and crc32 tail are not included. The chunk data consists of a single
        ///     grayscale chroma key value, narrowed to this PNG’s color depth,
        ///     if it has an opaque grayscale pixel format, an RGB chroma key triple,
        ///     narrowed to this PNG’s color depth, if it has an opaque RGB pixel
        ///     format, and the transparency values in this PNG’s color palette,
        ///     if it has an indexed color format. In the indexed color case, trailing
        ///     opaque palette entries are trimmed from the outputted sequence of
        ///     transparency values. If all palette entries are opaque, or this
        ///     `Properties` record has not been assigned a palette, `nil` is returned.
        func encodetRNS() -> [UInt8]?
    }

    /// A namespace for PNG image data container types.
    enum Data
    {
        typealias Ancillaries = (unique:[Chunk.Unique: [UInt8]], repeatable:[(Chunk.Repeatable, [UInt8])])
        
        /// A PNG image that has been decompressed, but not necessarily deinterlaced.
        struct Uncompressed
        {
            /// The global image `Properties` of this PNG image.
            let properties:Properties
            
            /// The buffer containing this PNG’s decoded, but not necessarily
            /// deinterlaced, image data.
            let data:[UInt8]
            
            /// Additional chunks not parsed by the library.
            let ancillaries:Ancillaries 
            
            /// Creates an uncompressed PNG image with the given pixel buffer and
            /// `Properties` record.
            /// 
            /// - Parameters:
            ///     - data: A pixel buffer.
            ///     - properties: A `Properties` record.
            ///     - ancillaries: Additional chunks to include in the image. Empty 
            ///         by default.
            /// - Returns: An uncompressed PNG image. If the size of the given
            ///     pixel buffer is not consistent with the size and format information
            ///     in the given `properties`, a fatal error will occur.
            init(rawData data:[UInt8], properties:Properties, ancillaries:Ancillaries = ([:], []))

            /// Decomposes this uncompressed image into its constituent sub-images,
            /// if this image is interlaced.
            /// 
            /// - Returns: The seven sub-images making up this image, if it uses
            ///     the Adam7 interlacing algorithm, and `nil` otherwise.
            func decomposed() -> [Rectangular]?

            /// Returns the pixels of this uncompressed image, organized into a
            /// rectangular row-major pixel matrix.
            /// 
            /// This method deinterlaces the pixel data from this uncompressed image,
            /// if it uses an interlacing algorithm. Otherwise, it simply repackages
            /// this image’s already-rectangular `data`.
            ///
            /// - Returns: A rectangular row-major pixel matrix.
            func deinterlaced() -> Rectangular

            /// Compresses this image, and outputs the compressed PNG file to the given
            /// data destination.
            /// 
            /// Excessively small chunk sizes may harm image compression. Higher
            /// compression levels produce smaller PNG files, but take longer to
            /// run.
            /// 
            /// - Parameters:
            ///     - destination: A data destination to write the contents of the
            ///         compressed file to.
            ///     - chunkSize: The maximum IDAT chunk size to use. The default
            ///         is 65536 bytes.
            ///     - level: The level of LZ77 compression to use. Must be in the
            ///         range `0 ... 9`, where 0 is no compression, and 9 is maximal
            ///         compression.
            func compress<Destination>(to destination:inout Destination,
                chunkSize:Int = 1 << 16, level:Int = 9) throws
                where Destination:DataDestination
            
            /// Decompresses a PNG file from the given data source, and returns
            /// it as an `Uncompressed` image.
            /// 
            /// - Parameters:
            ///     - source: A data source yielding a PNG file.
            /// - Returns: An uncompressed PNG image.
            static
            func decompress<Source>(from source:inout Source) throws -> Uncompressed
                where Source:DataSource

            /// Compresses and saves this PNG image at the given file path.
            /// 
            /// Excessively small chunk sizes may harm image compression. Higher
            /// compression levels produce smaller PNG files, but take longer to
            /// run.
            /// 
            /// - Parameters:
            ///     - outputPath: A file path.
            ///     - chunkSize: The maximum IDAT chunk size to use. The default
            ///         is 65536 bytes.
            ///     - level: The level of LZ77 compression to use. Must be in the
            ///         range `0 ... 9`, where 0 is no compression, and 9 is maximal
            ///         compression.
            /// - Returns: `nil` if the given file could not be opened.
            func compress(path outputPath:String, chunkSize:Int = 1 << 16, level:Int = 9) throws

            /// Decompresses a PNG file at the given file path, and returns it as 
            /// an `Uncompressed` image.
            /// 
            /// - Parameters:
            ///     - inputPath: A path to a PNG file.
            /// - Returns: An uncompressed PNG image, or `nil` if the given file
            ///     could not be opened.
            static
            func decompress(path inputPath:String) throws -> Uncompressed
            
            /// Converts the given indexed-representation RGBA image to the specified 
            /// target format.
            /// 
            /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
            /// 
            /// - Parameters:
            ///     - indices: An array of indices into the given `palette`, representing 
            ///         an image. No index may be greater than `palette.count`.
            ///     - palette: A palette of RGBA colors. 
            ///     - size: The size of the given image. The value `size.x * size.y` 
            ///         must be the same as `indices.count`.
            ///     - code: The color format to convert the input image to. All 
            ///         cases are valid, but some may result in data narrowing.
            ///     - chromaKey: A chroma key, or `nil`. The default is `nil`. 
            ///     - ancillaries: Extra PNG chunks to include in the image. Empty 
            ///         by default.
            ///
            /// - Returns: An `Uncompressed` image of the given color format.
            /// 
            /// - Throws: 
            ///     - ConversionError.pixelCount: if the `indices` array is the 
            ///         wrong size.
            ///     - ConversionError.indexOutOfRange: if a pixel index references 
            ///         a nonexistent palette entry.
            ///     - ConversionError.paletteOverflow: if the provided `palette` 
            ///         contains too many entries to be encoded in a specified 
            ///         indexing format.
            static
            func convert<Component>(indices:[Int], palette:[RGBA<Component>], 
                size:(x:Int, y:Int), to code:Properties.Format.Code, 
                chromaKey:RGBA<UInt16>? = nil, ancillaries:Ancillaries = ([:], []))
                throws -> Uncompressed 
                where Component:FixedWidthInteger & UnsignedInteger
            
            /// Converts the given grayscale image to the specified target format.
            /// 
            /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
            /// 
            /// - Parameters:
            ///     - v: An array of grayscale pixel values, representing 
            ///         an image.
            ///     - size: The size of the given image. The value `size.x * size.y` 
            ///         must be the same as `v.count`.
            ///     - code: The color format to convert the input image to. All 
            ///         cases are valid, but some may result in data narrowing.
            ///     - chromaKey: A chroma key, or `nil`. The default is `nil`. 
            ///     - ancillaries: Extra PNG chunks to include in the image. Empty 
            ///         by default.
            ///
            /// - Returns: An `Uncompressed` image of the given color format.
            /// 
            /// - Throws: 
            ///     - ConversionError.pixelCount: if the `v` array is the wrong
            ///         size.
            ///     - ConversionError.paletteOverflow: if the provided image contains
            ///         too many distinct colors to be encoded in a specified 
            ///         indexing format.
            static
            func convert<Component>(v:[Component],
                size:(x:Int, y:Int), to code:Properties.Format.Code, 
                chromaKey:RGBA<UInt16>? = nil, ancillaries:Ancillaries = ([:], []))
                throws -> Uncompressed
                where Component:FixedWidthInteger & UnsignedInteger
            
            /// Converts the given grayscale–alpha image to the specified target format.
            /// 
            /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
            /// 
            /// - Parameters:
            ///     - va: An array of grayscale–alpha pixel values, representing 
            ///         an image.
            ///     - size: The size of the given image. The value `size.x * size.y` 
            ///         must be the same as `va.count`.
            ///     - code: The color format to convert the input image to. All 
            ///         cases are valid, but some may result in data narrowing.
            ///     - chromaKey: A chroma key, or `nil`. The default is `nil`. 
            ///     - ancillaries: Extra PNG chunks to include in the image. Empty 
            ///         by default.
            ///
            /// - Returns: An `Uncompressed` image of the given color format.
            /// 
            /// - Throws: 
            ///     - ConversionError.pixelCount: if the `va` array is the wrong
            ///         size.
            ///     - ConversionError.paletteOverflow: if the provided image contains
            ///         too many distinct colors to be encoded in a specified 
            ///         indexing format.
            static
            func convert<Component>(va:[VA<Component>],
                size:(x:Int, y:Int), to code:Properties.Format.Code, 
                chromaKey:RGBA<UInt16>? = nil, ancillaries:Ancillaries = ([:], []))
                throws -> Uncompressed
                where Component:FixedWidthInteger & UnsignedInteger
            
            /// Converts the given RGBA image to the specified target format.
            /// 
            /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
            /// 
            /// - Parameters:
            ///     - rgba: An array of RGBA pixel values, representing an image.
            ///     - size: The size of the given image. The value `size.x * size.y` 
            ///         must be the same as `rgba.count`.
            ///     - code: The color format to convert the input image to. All 
            ///         cases are valid, but some may result in data narrowing.
            ///     - chromaKey: A chroma key, or `nil`. The default is `nil`. 
            ///     - ancillaries: Extra PNG chunks to include in the image. Empty 
            ///         by default.
            ///
            /// - Returns: An `Uncompressed` image of the given color format.
            /// 
            /// - Throws: 
            ///     - ConversionError.pixelCount: if the `rgba` array is the wrong
            ///         size.
            ///     - ConversionError.paletteOverflow: if the provided image contains
            ///         too many distinct colors to be encoded in a specified 
            ///         indexing format.
            static
            func convert<Component>(rgba:[RGBA<Component>],
                size:(x:Int, y:Int), to code:Properties.Format.Code, 
                chromaKey:RGBA<UInt16>? = nil, ancillaries:Ancillaries = ([:], []))
                throws -> Uncompressed
                where Component:FixedWidthInteger & UnsignedInteger
        }

        /// A PNG image that has been deinterlaced, but may still have multiple
        /// pixels packed per byte, or indirect (indexed) pixels.
        struct Rectangular
        {
            /// The global image `Properties` of this PNG image.
            let properties:Properties
            
            /// A rectangular row-major matrix containing this PNG’s pixel data.
            /// This buffer is untyped, and each byte may contain multiple, or
            /// fractional, pixels. Logical image scanlines are padded to a whole
            /// number of bytes.
            let data:[UInt8]
            
            /// Additional chunks not parsed by the library.
            let ancillaries:Ancillaries 
            
            /// Creates a fully decoded PNG image with the given pixel matrix and
            /// `Properties` record.
            /// 
            /// - Parameters:
            ///     - data: An untyped, padded data buffer containing a row-major
            ///         pixel matrix.
            ///     - properties: A `Properties` record.
            ///     - ancillaries: Additional chunks to include in the image. Empty 
            ///         by default.
            /// - Returns: A fully decoded PNG image. The size of the given pixel
            ///     matrix must be consistent with the size and format information
            ///     in the given image `properties`.
            init(rawData data:[UInt8], properties:Properties, ancillaries:Ancillaries = ([:], []))

            /// Decompresses and deinterlaces a PNG file at the given file path,
            /// and returns it as a `Rectangular` row-major pixel matrix.
            /// 
            /// If the PNG file is not interlaced, no deinterlacing is performed.
            /// 
            /// - Parameters:
            ///     - inputPath: A path to a PNG file.
            /// - Returns: A rectangular row-major pixel matrix, or `nil` if the
            ///     given file could not be opened.
            static
            func decompress(path inputPath:String) throws -> Rectangular

            /// Calls the given closure on each single-channel pixel in this PNG 
            /// image.
            /// 
            /// The given closure is not called if this image does not have
            /// exactly one channel, or `Sample` does not have enough bits to represent
            /// its channel. The samples passed to the closure are raw, unnormalized
            /// scalars, cast to the inferred integer type.
            /// 
            /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, `UInt`, and `Int`.
            /// 
            /// - Parameters:
            ///     - body: A closure that takes one channel of one pixel.
            /// 
            /// - Returns: An array of the return values of the given closure, or
            ///     `nil`, if this PNG image has more than one channel, or `Sample`
            ///     does not have enough bits to represent its channel.
            func map<Sample, Result>(_ body:(Sample) -> Result) -> [Result]?
                where Sample:FixedWidthInteger
            
            /// Calls the given closure on the normalized intensity of each
            /// single-channel pixel in this PNG image.
            /// 
            /// The given closure is not called if this image does not have
            /// exactly one channel. The samples passed to the closure are normalized
            /// values in the range `0 ... Sample.max`.
            /// 
            /// To avoid information loss, you may want to check if this image’s
            /// component type has too many bits to be represented by the destination
            /// component type. This method should not be called using an integer
            /// type less than 8 bits wide.
            /// 
            /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
            /// 
            /// - Parameters:
            ///     - body: A closure that takes one normalized channel of one pixel.
            /// 
            /// - Returns: An array of the return values of the given closure, or
            ///     `nil`, if this PNG image has more than one channel.
            func mapIntensity<Sample, Result>(_ body:(Sample) -> Result) -> [Result]?
                where Sample:FixedWidthInteger & UnsignedInteger
            
            /// Calls the given closure on the normalized intensity of each
            /// two-channel pixel in this PNG image.
            /// 
            /// The given closure is not called if this image does not have
            /// exactly two channels. The samples passed to the closure are normalized
            /// values in the range `0 ... Sample.max`.
            /// 
            /// To avoid information loss, you may want to check if this image’s
            /// component type has too many bits to be represented by the destination
            /// component type. This method should not be called using an integer
            /// type less than 8 bits wide.
            /// 
            /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
            /// 
            /// - Parameters:
            ///     - body: A closure that takes two normalized channels of one pixel.
            /// 
            /// - Returns: An array of the return values of the given closure, or
            ///     `nil`, if this PNG image does not have exactly two channels.
            func mapIntensity<Sample, Result>(_ body:(Sample, Sample) -> Result) -> [Result]?
                where Sample:FixedWidthInteger & UnsignedInteger
            
            /// Calls the given closure on the normalized intensity of each
            /// three-channel pixel in this PNG image.
            /// 
            /// The given closure is not called if this PNG image does not have
            /// exactly three channels. The samples passed to the closure are normalized
            /// values in the range `0 ... Sample.max`.
            /// 
            /// To avoid information loss, you may want to check if this image’s
            /// component type has too many bits to be represented by the destination
            /// component type. This method should not be called using an integer
            /// type less than 8 bits wide.
            /// 
            /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
            /// 
            /// - Parameters:
            ///     - body: A closure that takes three normalized channels of one
            ///         pixel.
            /// 
            /// - Returns: An array of the return values of the given closure, or
            ///     `nil`, if this PNG image does not have exactly three channels.
            func mapIntensity<Sample, Result>(_ body:(Sample, Sample, Sample) -> Result) -> [Result]?
                where Sample:FixedWidthInteger & UnsignedInteger
            
            /// Calls the given closure on the normalized intensity of each
            /// four-channel pixel in this PNG image.
            /// 
            /// The given closure is not called if this image does not have
            /// exactly four channels. The samples passed to the closure are normalized
            /// values in the range `0 ... Sample.max`.
            /// 
            /// To avoid information loss, you may want to check if this image’s
            /// component type has too many bits to be represented by the destination
            /// component type. This method should not be called using an integer
            /// type less than 8 bits wide.
            /// 
            /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
            /// 
            /// - Parameters:
            ///     - body: A closure that takes four normalized channels of one
            ///         pixel.
            /// 
            /// - Returns: An array of the return values of the given closure, or
            ///     `nil`, if this PNG image does not have exactly four channels.
            func mapIntensity<Sample, Result>(_ body:(Sample, Sample, Sample, Sample) -> Result) -> [Result]?
                where Sample:FixedWidthInteger & UnsignedInteger

            /// Returns a row-major matrix of the first components of all the pixels
            /// in this PNG image, normalized to the range of the given component type.
            /// 
            /// If this image has more than one component per pixel, the first
            /// component of each pixel is returned. If this image has indexed color,
            /// the components returned are the first components of the RGB palette
            /// colors of those pixels. This method ignores the transparency and
            /// chroma keys of this image.
            /// 
            /// To avoid information loss, you may want to check if this image’s
            /// component type has too many bits to be represented by the destination
            /// component type. This method should not be called using an integer
            /// type less than 8 bits wide.
            /// 
            /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`,
            /// `UInt64`, and `UInt`.
            /// 
            /// - Parameters:
            ///     - type: An integer type.
            /// - Returns: A row-major matrix of pixel values, normalized to its
            ///     `Component` type, or `nil` if this image requires a palette, and
            ///     it does not have one.
            func v<Component>(of type:Component.Type) -> [Component]
                where Component:FixedWidthInteger & UnsignedInteger
            
            /// Returns a row-major matrix of the grayscale-alpha color values represented
            /// by all the pixels in this PNG image, normalized to the range of
            /// the given component type.
            /// 
            /// If this image has grayscale color, the grayscale-alpha colors returned
            /// share the value component, and have `Component.max` in the alpha
            /// component. If this image has RGB color, the grayscale-alpha colors
            /// have the red component in the value component, and have `Component.max`
            /// in the alpha component. If this image has RGBA color, the grayscale-alpha
            /// colors share the alpha component in addition.
            /// 
            /// To avoid information loss, you may want to check if this image’s
            /// component type has too many bits to be represented by the destination
            /// component type. This method should not be called using an integer
            /// type less than 8 bits wide.
            /// 
            /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`,
            /// `UInt64`, and `UInt`.
            /// 
            /// - Parameters:
            ///     - type: An integer type.
            /// - Returns: A row-major matrix of grayscale-alpha pixel colors, normalized
            ///     to the given `Component` type, or `nil` if this image requires
            ///     a palette, and it does not have one.
            func va<Component>(of type:Component.Type) -> [VA<Component>]
                where Component:FixedWidthInteger & UnsignedInteger
            
            /// Returns a row-major matrix of the RGBA color values represented
            /// by all the pixels in this PNG image, normalized to the range of
            /// the given component type.
            /// 
            /// If this image has grayscale color, the RGBA colors returned have
            /// the value component in the red, green, and blue components, and
            /// `Component.max` in the alpha component. If this image has grayscale-alpha
            /// color, the RGBA colors returned share the alpha component in addition.
            /// If this image has RGB color, the RGBA colors share the red, green,
            /// and blue components, and have `Component.max` in the alpha component.
            /// 
            /// To avoid information loss, you may want to check if this image’s
            /// component type has too many bits to be represented by the destination
            /// component type. This method should not be called using an integer
            /// type less than 8 bits wide.
            /// 
            /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`,
            /// `UInt64`, and `UInt`.
            /// 
            /// - Parameters:
            ///     - type: An integer type.
            /// - Returns: A row-major matrix of RGBA pixel colors, normalized to
            ///     the given `Component` type, or `nil` if this image requires
            ///     a palette, and it does not have one.
            func rgba<Component>(of type:Component.Type) -> [RGBA<Component>]
                where Component:FixedWidthInteger & UnsignedInteger

            /// Returns a row-major matrix of the RGBA color values represented
            /// by all the pixels in this PNG image, normalized to the range of
            /// the given component type and encoded as integer slugs containing
            /// four components in ARGB order. The alpha components are premultiplied
            /// into the colors.
            /// 
            /// If this image has grayscale color, the RGBA colors returned have
            /// the value component in the red, green, and blue components, and
            /// `Component.max` in the alpha component. If this image has grayscale-alpha
            /// color, the RGBA colors returned share the alpha component in addition.
            /// If this image has RGB color, the RGBA colors share the red, green,
            /// and blue components, and have `Component.max` in the alpha component.
            /// The RGBA colors are packed into four-component integer slugs of a
            /// type large enough to hold four instances of the given type, if one
            /// exists. The color components are packed in ARGB order, with alpha
            /// in the high bits.
            /// 
            /// Allowed `Component` types by default are `UInt8`, and `UInt16`.
            /// Custom `Component` types can be used by conforming them to the
            /// `FusedVector4Element` protocol and supplying the `FusedVector4`
            /// associatedtype. This type must satisfy `Self.bitWidth == Component.bitWidth << 2`.
            /// 
            /// To avoid information loss, you may want to check if this image’s
            /// component type has too many bits to be represented by the destination
            /// component type. This method should not be called using an integer
            /// type less than 8 bits wide.
            /// 
            /// *Specialized* for `Component` types `UInt8` and `UInt16`.
            /// (`Component.FusedVector4` types `UInt32` and `UInt64`.)
            /// 
            /// - Parameters:
            ///     - type: An integer type.
            /// - Returns: A row-major matrix of RGBA pixel colors, normalized to
            ///     the given `Component` type, and encoded as four-component integer
            ///     slugs, or `nil` if this image requires a palette, and
            ///     it does not have one.
            func argbPremultiplied<Component>(of type:Component.Type)
                -> [Component.FusedVector4] where Component:FusedVector4Element
        }
    }
    
    /// Returns a row-major matrix of the first components of all the pixels
    /// in this PNG file, normalized to the range of the given component type.
    /// 
    /// If this image has more than one component per pixel, the first
    /// component of each pixel is returned. If this image has indexed color,
    /// the components returned are the first components of the RGB palette
    /// colors of those pixels. This method ignores the transparency and
    /// chroma keys of this image.
    /// 
    /// To avoid information loss, you may want to check if this image’s
    /// component type has too many bits to be represented by the destination
    /// component type. This method should not be called using an integer
    /// type less than 8 bits wide.
    /// 
    /// - Parameters:
    ///     - path: A path to a PNG file.
    ///     - type: An integer type.
    /// - Returns: A tuple containing a row-major matrix of pixel components, normalized
    ///     to its `Component` type, and the logical pixel dimensions of the matrix.
    static
    func v<Component>(path:String, of type:Component.Type) throws
        -> (pixels:[Component], size:(x:Int, y:Int))
        where Component:FixedWidthInteger & UnsignedInteger

    /// Returns a row-major matrix of the grayscale-alpha color values represented
    /// by all the pixels in this PNG file, normalized to the range of
    /// the given component type.
    /// 
    /// If this image has grayscale color, the grayscale-alpha colors returned
    /// share the value component, and have `Component.max` in the alpha
    /// component. If this image has RGB color, the grayscale-alpha colors
    /// have the red component in the value component, and have `Component.max`
    /// in the alpha component. If this image has RGBA color, the grayscale-alpha
    /// colors share the alpha component in addition.
    /// 
    /// To avoid information loss, you may want to check if this image’s
    /// component type has too many bits to be represented by the destination
    /// component type. This method should not be called using an integer
    /// type less than 8 bits wide.
    /// 
    /// - Parameters:
    ///     - path: A path to a PNG file.
    ///     - type: An integer type.
    /// - Returns: A tuple containing a row-major matrix of pixel components, normalized
    ///     to its `Component` type, and the logical pixel dimensions of the matrix.
    static
    func va<Component>(path:String, of type:Component.Type) throws
        -> (pixels:[VA<Component>], size:(x:Int, y:Int))
        where Component:FixedWidthInteger & UnsignedInteger

    /// Returns a row-major matrix of the RGBA color values represented
    /// by all the pixels in this PNG file, normalized to the range of
    /// the given component type.
    /// 
    /// If this image has grayscale color, the RGBA colors returned have
    /// the value component in the red, green, and blue components, and
    /// `Component.max` in the alpha component. If this image has grayscale-alpha
    /// color, the RGBA colors returned share the alpha component in addition.
    /// If this image has RGB color, the RGBA colors share the red, green,
    /// and blue components, and have `Component.max` in the alpha component.
    /// 
    /// To avoid information loss, you may want to check if this image’s
    /// component type has too many bits to be represented by the destination
    /// component type. This method should not be called using an integer
    /// type less than 8 bits wide.
    /// 
    /// - Parameters:
    ///     - path: A path to a PNG file.
    ///     - type: An integer type.
    /// - Returns: A tuple containing a row-major matrix of pixel components, normalized
    ///     to its `Component` type, and the logical pixel dimensions of the matrix.
    static
    func rgba<Component>(path:String, of type:Component.Type) throws
        -> (pixels:[RGBA<Component>], size:(x:Int, y:Int))
        where Component:FixedWidthInteger & UnsignedInteger

    /// Returns a row-major matrix of the RGBA color values represented
    /// by all the pixels in this PNG file, normalized to the range of
    /// the given component type and encoded as integer slugs containing
    /// four components in ARGB order. The alpha components are premultiplied
    /// into the colors.
    /// 
    /// If this image has grayscale color, the RGBA colors returned have
    /// the value component in the red, green, and blue components, and
    /// `Component.max` in the alpha component. If this image has grayscale-alpha
    /// color, the RGBA colors returned share the alpha component in addition.
    /// If this image has RGB color, the RGBA colors share the red, green,
    /// and blue components, and have `Component.max` in the alpha component.
    /// The RGBA colors are packed into four-component integer slugs of a
    /// type large enough to hold four instances of the given type, if one
    /// exists. The color components are packed in ARGB order, with alpha
    /// in the high bits.
    /// 
    /// Allowed `Component` types by default are `UInt8`, and `UInt16`.
    /// Custom `Component` types can be used by conforming them to the
    /// `FusedVector4Element` protocol and supplying the `FusedVector4`
    /// associatedtype. This type must satisfy `Self.bitWidth == Component.bitWidth << 2`.
    /// 
    /// To avoid information loss, you may want to check if this image’s
    /// component type has too many bits to be represented by the destination
    /// component type. This method should not be called using an integer
    /// type less than 8 bits wide.
    /// 
    /// - Parameters:
    ///     - path: A path to a PNG file.
    ///     - type: An integer type.
    /// - Returns: A tuple containing a row-major matrix of pixel components, normalized
    ///     to its `Component` type, and encoded as four-component integer slugs,
    ///     and the logical pixel dimensions of the matrix.
    static
    func argbPremultiplied<Component>(path:String, of type:Component.Type) throws
        -> (pixels:[Component.FusedVector4], size:(x:Int, y:Int))
        where Component:FusedVector4Element

    /// Encodes the given indexed-representation RGBA image in the specified 
    /// target format.
    /// 
    /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
    /// 
    /// - Parameters:
    ///     - indices: An array of indices into the given `palette`, representing 
    ///         an image. No index may be greater than `palette.count`.
    ///     - palette: A palette of RGBA colors. 
    ///     - size: The size of the given image. The value `size.x * size.y` 
    ///         must be the same as `indices.count`.
    ///     - code: The color format to convert the input image to. All 
    ///         cases are valid, but some may result in data narrowing.
    ///     - chromaKey: A chroma key, or `nil`. The default is `nil`. 
    ///     - path: A file path to write the encoded PNG file to.
    ///     - ancillaries: Extra PNG chunks to include in the image. Empty 
    ///         by default.
    ///
    /// - Throws: 
    ///     - ConversionError.pixelCount: if the `indices` array is the 
    ///         wrong size.
    ///     - ConversionError.indexOutOfRange: if a pixel index references 
    ///         a nonexistent palette entry.
    ///     - ConversionError.paletteOverflow: if the provided `palette` 
    ///         contains too many entries to be encoded in a specified 
    ///         indexing format.
    ///     - File.Error.couldNotOpen: if the file at the given `path` could not 
    ///         be found or opened.
    static
    func encode<Component>(indices:[Int], palette:[RGBA<Component>], size:(x:Int, y:Int),
        as code:Properties.Format.Code, chromaKey:RGBA<UInt16>? = nil,
        path outputPath:String, level:Int = 9) throws
        where Component:FixedWidthInteger & UnsignedInteger

    /// Encodes the given grayscale image in the specified target format.
    /// 
    /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
    /// 
    /// - Parameters:
    ///     - v: An array of grayscale pixel values, representing 
    ///         an image.
    ///     - size: The size of the given image. The value `size.x * size.y` 
    ///         must be the same as `v.count`.
    ///     - code: The color format to convert the input image to. All 
    ///         cases are valid, but some may result in data narrowing.
    ///     - chromaKey: A chroma key, or `nil`. The default is `nil`. 
    ///     - path: A file path to write the encoded PNG file to.
    ///     - ancillaries: Extra PNG chunks to include in the image. Empty 
    ///         by default.
    /// 
    /// - Throws: 
    ///     - ConversionError.pixelCount: if the `v` array is the wrong
    ///         size.
    ///     - ConversionError.paletteOverflow: if the provided image contains
    ///         too many distinct colors to be encoded in a specified 
    ///         indexing format.
    ///     - File.Error.couldNotOpen: if the file at the given `path` could not 
    ///         be found or opened.
    static
    func encode<Component>(v:[Component], size:(x:Int, y:Int),
        as code:Properties.Format.Code, chromaKey:RGBA<UInt16>? = nil,
        path outputPath:String, level:Int = 9) throws
        where Component:FixedWidthInteger & UnsignedInteger
        
    /// Converts the given grayscale–alpha image to the specified target format.
    /// 
    /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
    /// 
    /// - Parameters:
    ///     - va: An array of grayscale–alpha pixel values, representing 
    ///         an image.
    ///     - size: The size of the given image. The value `size.x * size.y` 
    ///         must be the same as `va.count`.
    ///     - code: The color format to convert the input image to. All 
    ///         cases are valid, but some may result in data narrowing.
    ///     - chromaKey: A chroma key, or `nil`. The default is `nil`. 
    ///     - path: A file path to write the encoded PNG file to.
    ///     - ancillaries: Extra PNG chunks to include in the image. Empty 
    ///         by default.
    /// 
    /// - Throws: 
    ///     - ConversionError.pixelCount: if the `va` array is the wrong
    ///         size.
    ///     - ConversionError.paletteOverflow: if the provided image contains
    ///         too many distinct colors to be encoded in a specified 
    ///         indexing format.
    ///     - File.Error.couldNotOpen: if the file at the given `path` could not 
    ///         be found or opened.
    static
    func encode<Component>(va:[VA<Component>], size:(x:Int, y:Int),
        as code:Properties.Format.Code, chromaKey:RGBA<UInt16>? = nil,
        path outputPath:String, level:Int = 9) throws
        where Component:FixedWidthInteger & UnsignedInteger
    
    /// Converts the given RGBA image to the specified target format.
    /// 
    /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
    /// 
    /// - Parameters:
    ///     - rgba: An array of RGBA pixel values, representing an image.
    ///     - size: The size of the given image. The value `size.x * size.y` 
    ///         must be the same as `rgba.count`.
    ///     - code: The color format to convert the input image to. All 
    ///         cases are valid, but some may result in data narrowing.
    ///     - chromaKey: A chroma key, or `nil`. The default is `nil`. 
    ///     - path: A file path to write the encoded PNG file to.
    ///     - ancillaries: Extra PNG chunks to include in the image. Empty 
    ///         by default.
    /// 
    /// - Throws: 
    ///     - ConversionError.pixelCount: if the `rgba` array is the wrong
    ///         size.
    ///     - ConversionError.paletteOverflow: if the provided image contains
    ///         too many distinct colors to be encoded in a specified 
    ///         indexing format.
    ///     - File.Error.couldNotOpen: if the file at the given `path` could not 
    ///         be found or opened.
    static
    func encode<Component>(rgba:[RGBA<Component>], size:(x:Int, y:Int),
        as code:Properties.Format.Code, chromaKey:RGBA<UInt16>? = nil,
        path outputPath:String, level:Int = 9) throws
        where Component:FixedWidthInteger & UnsignedInteger
    
    /// A PNG chunk type.
    enum Chunk 
    {
        /// A PNG chunk type recognized and parsed by the library.
        enum Core 
        {
            case    header, 
                    palette, 
                    data, 
                    end, 
                    transparency 
        }
        
        /// A PNG chunk type not parsed by the library, which can only occur 
        /// once in a PNG file.
        enum Unique 
        {
            case    chromaticity, 
                    gamma, 
                    profile, 
                    significantBits, 
                    srgb, 
                    background, 
                    histogram, 
                    physicalDimensions, 
                    time 
            
            /// Whether or not this chunk is safe to copy over if image data has 
            /// been modified.
            var safeToCopy:Bool 
        }
        
        /// A PNG chunk type not parsed by the library, which can occur multiple 
        /// times in a PNG file.
        enum Repeatable 
        {
            case    suggestedPalette, 
                    textUTF8, 
                    textLatin1, 
                    textLatin1Compressed, 
                    other(Other) 
            
            /// A non-standard private PNG chunk type.
            struct Other 
            {
                /// This chunk’s tag
                let tag:Tag 
                
                /// Creates a private PNG chunk type identifier from the given 
                /// tag bytes. 
                /// 
                /// This initializer will trap if the given bytes do not form 
                /// a valid chunk tag, or if the tag represents a chunk type 
                /// defined by the library. To handle these situations, use the 
                /// `Chunk(_:)` initializer and switch on its enumeration cases 
                /// instead.
                /// 
                /// - Parameters:
                ///     - name: The four bytes of this PNG chunk type’s name.
                init(_ name:(UInt8, UInt8, UInt8, UInt8)) 
            }
            
            /// Whether or not this chunk is safe to copy over if image data has 
            /// been modified.
            var safeToCopy:Bool 
        }
        
        case    core(Core), 
                unique(Unique), 
                repeatable(Repeatable)
        
        /// Classifies the given chunk tag. 
        /// 
        /// - Parameters:
        ///     - tag: A PNG chunk tag.
        init(_ tag:Tag) 
        
        /// A four-byte PNG chunk type identifier.
        struct Tag:Hashable, Equatable, CustomStringConvertible
        {
            /// A string displaying the ASCII representation of this PNG chunk type’s name.
            var description:String

            /// Creates the chunk type with the given name bytes, if they are valid.
            /// Returns `nil` if the ancillary bit (in byte 0) is set or the reserved
            /// bit (in byte 2) is set, and the ASCII name is not one of `IHDR`, `PLTE`,
            /// `IDAT`, `IEND`, `cHRM`, `gAMA`, `iCCP`, `sBIT`, `sRGB`, `bKGD`, `hIST`,
            /// `tRNS`, `pHYs`, `sPLT`, `tIME`, `iTXt`, `tEXt`, or `zTXt`.
            /// 
            /// - Parameters:
            ///     - name: The four bytes of this PNG chunk type’s name.
            init?(_ name:(UInt8, UInt8, UInt8, UInt8))

            /// Returns a Boolean value indicating whether two PNG chunk types are equal.
            /// 
            /// Equality is the inverse of inequality. For any values `a` and `b`, `a == b`
            /// implies that `a != b` is `false`.
            /// 
            /// - Parameters:
            ///     - lhs: A value to compare.
            ///     - rhs: Another value to compare.
            static
            func == (a:Tag, b:Tag) -> Bool

            /// Hashes the name of this PNG chunk type by feeding it into the given
            /// hasher.
            /// 
            /// - Parameters:
            ///     - hasher: The hasher to use when combining the components of this
            ///         instance.
            func hash(into hasher:inout Hasher)

            /// The PNG header chunk type.
            static
            let IHDR:Tag
            /// The PNG palette chunk type.
            static 
            let PLTE:Tag
            /// The PNG image data chunk type.
            static
            let IDAT:Tag
            /// The PNG image end chunk type.
            static
            let IEND:Tag

            /// The PNG chromaticity chunk type.
            static
            let cHRM:Tag
            /// The PNG gamma chunk type.
            static
            let gAMA:Tag
            /// The PNG embedded ICC chunk type.
            static
            let iCCP:Tag
            /// The PNG significant bits chunk type.
            static
            let sBIT:Tag
            /// The PNG *s*RGB chunk type.
            static
            let sRGB:Tag
            /// The PNG background chunk type.
            static
            let bKGD:Tag
            /// The PNG histogram chunk type.
            static
            let hIST:Tag
            /// The PNG transparency chunk type.
            static
            let tRNS:Tag

            /// The PNG physical dimensions chunk type.
            static
            let pHYs:Tag

            /// The PNG suggested palette chunk type.
            static
            let sPLT:Tag
            /// The PNG time chunk type.
            static
            let tIME:Tag

            /// The PNG UTF-8 text chunk type.
            static
            let iTXt:Tag
            /// The PNG Latin-1 text chunk type.
            static
            let tEXt:Tag
            /// The PNG compressed Latin-1 text chunk type.
            static
            let zTXt:Tag
        }

    /// Errors that can occur while reading, decompressing, or decoding PNG files.
    enum DecodingError:Error
    {
        /// A PNG file is missing its magic signature.
        case missingSignature

        /// A data interface is unable to provide requested data.
        case dataUnavailable

        /// An image data buffer does not match the shape specified by an associated
        /// `Properties` record
        case inconsistentMetadata

        /// A PNG chunk has a type-specific validity error.
        case invalidChunk(message:String)
        /// A PNG chunk has an invalid type name.
        case invalidName((UInt8, UInt8, UInt8, UInt8))

        /// A PNG chunk’s crc32 value indicates it has been corrupted.
        case corruptedChunk(Chunk)
        /// A PNG chunk has been encountered which cannot appear assuming a particular
        /// sequence of preceeding chunks have been encountered.
        case unexpectedChunk(Chunk)

        /// A PNG chunk has been encountered that is of the same type as a previously
        /// encountered chunk, and is of a type which cannot appear multiple times
        /// in the same PNG file.
        case duplicateChunk(Chunk)
        /// A prerequisite PNG chunk is missing.
        case missingChunk(Chunk.Core)
    }
     
    enum ConversionError:Error 
    {
        /// An input pixel array has the wrong size 
        case pixelCount
        /// An image being encoded has too many colors to index.
        case paletteOverflow
        /// An indexed pixel references a palette entry that doesn’t exist.
        case indexOutOfRange
    }

    /// Errors that can occur while writing, compressing, or encoding PNG files.
    enum EncodingError:Error
    {
        /// A data interface is unable to accept given data.
        case notAcceptingData
        /// An input scanline has the wrong size.
        case bufferCount
    }
    
    /// A low-level API for deconstructing a PNG file into its constituent untyped
    /// chunks, or constructing a PNG file out of a sequence of typed chunks.
    struct ChunkIterator<DataInterface>
    {
    }
}

extension PNG.ChunkIterator where DataInterface:DataSource
{
    /// Begins the process of loading untyped PNG chunks from the given data source.
    /// 
    /// The main operation performed this method is checking for the PNG magic file
    /// signature. This method will pull 8 bytes of data from the given data source.
    /// 
    /// - Parameters:
    ///     - source: A data source yielding a PNG file. The source is assumed to
    ///         pointing to the very beginning of the PNG file.
    /// - Returns: A chunk iterator, if the PNG magic signature was read from the
    ///     given data source, and `nil` otherwise.
    static
    func begin(source:inout DataInterface) -> PNG.ChunkIterator<DataInterface>?

    /// Loads the an untyped PNG chunk from the given data source.
    /// 
    /// This method performs no chunk name validation, nor does it interpret the chunk.
    /// This method does, however, perform crc32 validation on the chunk, as this
    /// is universal to all PNG chunks.
    /// 
    /// To aid diagnostics, the name bytes of the chunk are returned even if the
    /// chunk’s data is corrupted.
    /// 
    /// This method pulls 12 bytes from the given data source, plus the length encoded
    /// in the chunk header.
    /// 
    /// - Parameters:
    ///     - source: A data source yielding a PNG file.
    /// - Returns: A tuple containing the name bytes of the read chunk and its data,
    ///     or `nil` if enough data could not be pulled from the given data source.
    ///     The chunk `data` field of the tuple is `nil` if the chunk’s data could
    ///     be successfully read, but failed to match the chunk’s crc32 checksum.
    /// 
    /// - Note: Some chunks may have a length of 0, and such produce an empty `data`
    ///     array. This is not an error.
    mutating
    func next(source:inout DataInterface) -> (name:(UInt8, UInt8, UInt8, UInt8), data:[UInt8]?)?
}

extension PNG.ChunkIterator where DataInterface:DataDestination
{
    /// Begins the process of storing untyped PNG chunks into the given data destination.
    /// 
    /// The main operation performed this method is writing the PNG magic file signature.
    /// This method will push 8 bytes of data to the given data destination.
    /// 
    /// - Parameters:
    ///     - source: A data destination to write a PNG file to. The destination
    ///         is assumed to pointing to the very beginning of the file.
    /// - Returns: A chunk iterator, or `nil` if the signature could not be written.
    static
    func begin(destination:inout DataInterface) -> PNG.ChunkIterator<DataInterface>?

    /// Serializes a PNG chunk of the given type and with the given raw data, and
    /// stores it into the given data destination.
    /// 
    /// This method does not interpret the given chunk data. This method automatically
    /// computes its crc32 checksum, and chunk length, and stores them in its serialized
    /// in-file representation.
    /// 
    /// This method pushes 12 bytes to the given data destination, plus the given
    /// `data` array.
    /// 
    /// - Parameters:
    ///     - tag: A chunk tag.
    ///     - data: An array containing chunk data. The default is `[]`.
    ///     - source: A data destination to write a PNG file to.
    /// - Returns: `nil` if the chunk could not be written.
    mutating
    func next(_ tag:PNG.Chunk.Tag, _ data:[UInt8] = [], destination:inout DataInterface)
        -> Void?
}


protocol FixedLayoutColor:RandomAccessCollection, Hashable, CustomStringConvertible
    where Index == Int
{
    static
    var components:Int
    {
        get
    }
}
extension FixedLayoutColor
{
    var startIndex:Int
    {
        return 0
    }
    
    var endIndex:Int
    {
        return Self.components
    }
}

extension PNG.VA:FixedLayoutColor 
{
    /// A textual representation of this color.
    var description:String
    
    /// The number of components in this grayscale-alpha color, always 2.
    static
    var components:Int
    
    /// The `index`th component of this color. The 0th component is the grayscale 
    /// component, and the 1st component is the alpha component.
    subscript(index:Int) -> Component
}

extension PNG.RGBA:FixedLayoutColor
{
    /// A textual representation of this color.
    var description:String
    
    static
    var components:Int
    
    subscript(index:Int) -> Component
} 


extension Array where Element:FixedLayoutColor
{
    /// Converts this array of color values to a palette table and an array of indices.
    /// 
    /// - Returns: A tuple containing the indices of the colors in this array, and
    ///     a table of color palette entries, or `nil` if this array of color values
    ///     could not be indexed into 256 or fewer palette entries.
    func indexPalette() -> (indexed:[UInt8], palette:[Element])?

    /// Temporarily view this color matrix as a flattened buffer of interleaved
    /// color components.
    /// 
    /// *Inlinable*
    ///
    /// - Parameters:
    ///     - body: A closure taking a buffer pointer to this color matrix, viewed
    ///         as a flat buffer of interleaved color components.
    /// - Returns: The return value of `body`, if it has one.
    /// 
    /// - Note: The buffer passed to the closure is only valid for the execution
    ///     of that closure.
    func withUnsafeBufferPointerToComponents<Result>(_ body:(UnsafeBufferPointer<Element.Element>) throws -> Result)
        rethrows -> Result
    
    /// Converts this array of colorvectors into a planar representation. Other 
    /// frameworks may call this operation “unzip”.
    /// 
    /// *Inlinable*.
    /// 
    /// - Returns: If the original array contains colorvectors 
    ///     `[(a1, b1, c1, ...), (a2, b2, c2, ...), (a3, b3, c3, ...), ..., (an, bn, cn, ...)]`, 
    ///     the result will be an array of colorvector components 
    ///     `[a1, a2, a3, ..., an, b1, b2, b3, ..., bn, c1, c2, c3, ..., cn, ...]`.  
    func planar() -> [Element.Element]

    /// Flattens this array of colorvectors into an unstructured array of their 
    /// interleaved components.
    /// 
    /// *Inlinable*.
    /// 
    /// - Returns: If the original array contains colorvectors 
    ///     `[(a1, b1, c1, ...), (a2, b2, c2, ...), (a3, b3, c3, ...), ..., (an, bn, cn, ...)]`, 
    ///     the result will be an array of colorvector components 
    ///     `[a1, b1, c1, ..., a2, b2, c2, ..., a3, b3, c3, ..., an, bn, cn, ...]`.
    /// 
    /// - Note: In most cases, it is better to temporarily rebind a structured pixel
    ///     array to a flattened array type than to convert it to interleaved form.  
    func interleaved() -> [Element.Element]
}
