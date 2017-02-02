import Zlib
import Glibc

public
enum PNGError:Error
{
    case FileError,
         FiletypeError,
         IncompleteChunkError,
         UnexpectedCriticalChunkError(String),
         PNGSyntaxError(String),
         DataCorruptionError(String),

         DuplicateChunkError(String),
         ChunkOrderingError(String),
         MissingHeaderError,
         PrematureEOSError,
         PrematureIENDError
}

fileprivate
struct PNGConditions
{
    var seen = [Bool](repeating: false, count: PNGChunk._cases.count)
    var last_valid_chunk:PNGChunkType = PNGChunkType.__FIRST__

    subscript(ct:PNGChunkType) -> Bool
    {
        get
        {
            return self.seen[ct.rawValue]
        }

        set(v)
        {
            self.seen[ct.rawValue] = v
        }
    }

    mutating func update(_ chunk_type:PNGChunkType) throws
    {
        if self.last_valid_chunk == .__FIRST__ && chunk_type != .IHDR
        {
            throw PNGError.MissingHeaderError
        }
        else if self.last_valid_chunk == .IEND
        {
            throw PNGError.PrematureIENDError
        }
        if chunk_type == .IEND && !self[.IDAT] // separated from the switch block because it doesn’t work right for some reason
        {
            throw PNGError.PrematureIENDError
        }

        switch chunk_type
        {

            // these chunks must occur before PLTE
            case .cHRM, .gAMA, .iCCP, .sBIT, .sRGB, .bKGD, .hIST, .tRNS:
                if self[.PLTE]
                {
                    throw PNGError.ChunkOrderingError(chunk_type.description.1)
                }
                fallthrough

            // these chunks must occur before IDAT
            case .PLTE, .cHRM, .gAMA, .iCCP, .sBIT, .sRGB, .bKGD, .hIST, .tRNS, .pHYs, .sPLT:
                if self[.IDAT]
                {
                    throw PNGError.ChunkOrderingError(chunk_type.description.1)
                }
                fallthrough



            // these chunks cannot duplicate
            case .IHDR, .PLTE, .IEND, .cHRM, .gAMA, .iCCP, .sBIT, .sRGB, .bKGD, .hIST, .tRNS, .pHYs, .sPLT, .tIME, .iTXt, .tEXt, .zTXT:
                if self[chunk_type]
                {
                    throw PNGError.DuplicateChunkError(chunk_type.description.1)
                }

            // IDAT blocks much be consecutive
            case .IDAT:
                if self.last_valid_chunk != .IDAT && self[.IDAT]
                {
                    throw PNGError.ChunkOrderingError(chunk_type.description.1)
                }
            default:
                break
        }
        self.last_valid_chunk = chunk_type
        self[chunk_type] = true
    }
}

public
enum PNGChunkType:Int
{
    case __FIRST__ = 0,
         IHDR,
         PLTE,
         IDAT,
         IEND,

         cHRM,
         gAMA,
         iCCP,
         sBIT,
         sRGB,
         bKGD,
         hIST,
         tRNS,
         pHYs,
         sPLT,
         tIME,
         iTXt,
         tEXt,
         zTXT

    fileprivate
    var description:(String, String)
    {
        switch self
        {
            case .__FIRST__:
                return ("__FIRST__", "__FIRST__")
            case .IHDR:
                return ("IHDR", "image header")
            case .PLTE:
                return ("PLTE", "palatte")
            case .IDAT:
                return ("IDAT", "image pixel data")
            case .IEND:
                return ("IEND", "png file end")

            case .cHRM:
                return ("cHRM", "primary chromaticities")
            case .gAMA:
                return ("gAMA", "gamma exponent")
            case .iCCP:
                return ("iCCP", "ICC profile")
            case .sBIT:
                return ("sBIT", "significant bits")
            case .sRGB:
                return ("sRGB", "sRGB color space")
            case .bKGD:
                return ("bKGD", "default background color")
            case .hIST:
                return ("hIST", "palatte histogram")
            case .tRNS:
                return ("tRNS", "simple transparency")
            case .pHYs:
                return ("pHYs", "physical dimensions")
            case .sPLT:
                return ("sPLT", "suggested palatte")
            case .tIME:
                return ("tIME", "time modified")
            case .iTXt:
                return ("iTXt", "utf-8 text")
            case .tEXt:
                return ("tEXt", "ASCII text")
            case .zTXT:
                return ("zTXT", "compressed text")
        }
    }
}

fileprivate
struct PNGChunk
{
    static
    let _cases:[PNGChunkType] = PNGChunk._make_case_array()
    static private
    let _lookup:[Int: PNGChunkType] = PNGChunk._make_case_lookup(PNGChunk._cases)

    static private
    func _make_case_array() -> [PNGChunkType]
    {
        var cases:[PNGChunkType] = []
        var rv:Int = 0
        while let chunk_type = PNGChunkType(rawValue: rv)
        {
            cases.append(chunk_type)
            rv += 1
        }
        return cases
    }

    static private
    func _make_case_lookup(_ cases:[PNGChunkType]) -> [Int: PNGChunkType]
    {
        var lookup:[Int: PNGChunkType] = [:]
        for c in cases
        {
            lookup[quad_byte_to_int([UInt8](c.description.0.utf8))] = c
        }
        return lookup
    }

    static
    func from_buffer(_ buffer:[UInt8]) -> PNGChunkType?
    {
        return PNGChunk._lookup[quad_byte_to_int(buffer)]
    }

    static
    func string_rep(_ buffer:[UInt8]) -> String
    {
        var str = ""
        for c in buffer.flatMap(UnicodeScalar.init).map(Character.init)
        {
            str.append(c)
        }
        return str
    }
}

fileprivate
func quad_byte_to_int(_ buffer:[UInt8]) -> Int
{
    return Int(UInt32(bigEndian: buffer.withUnsafeBufferPointer {
     ($0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0 })
    }.pointee))
}

fileprivate
func read_png_buffer(_ f:UnsafeMutablePointer<FILE>, _ length:Int) throws -> [UInt8]
{
    var buffer = [UInt8](repeating: 0, count: length)
    guard fread(&buffer, 1, length, f) == length
    else
    {
        throw PNGError.IncompleteChunkError
    }
    return buffer
}

fileprivate
func png_skip_chunk_data(_ f:UnsafeMutablePointer<FILE>, _ length:Int) throws
{
    if length <= 128 // most regulated-length png chunks are shorter than 128 bytes
    {
        let _ = try read_png_buffer(f, length + 4)
    }
    else
    {
        fseek(f, length, SEEK_CUR)
        let _ = try read_png_buffer(f, 4) // read a throwaway buffer, also corresponds to CRC32
    }
}

fileprivate
func png_read_chunk(f:UnsafeMutablePointer<FILE>, conditions:inout PNGConditions, one_of:Set<PNGChunkType>) throws -> (chunk_type:PNGChunkType, chunk_data:[UInt8])?
{
    /* — CHUNK LENGTH READ — */
    let length:Int = quad_byte_to_int(try read_png_buffer(f, 4))

    /* — CHUNK TYPE READ AND VALIDATION — */
    let chunk_type_buffer = try read_png_buffer(f, 4)
    guard let chunk_type = PNGChunk.from_buffer(chunk_type_buffer)
    else
    {
        guard (chunk_type_buffer[0] & (1 << 5)) != 0
        else
        {
            throw PNGError.UnexpectedCriticalChunkError(PNGChunk.string_rep(chunk_type_buffer))
        }
        guard (chunk_type_buffer[2] & (1 << 5)) == 0
        else
        {
            throw PNGError.PNGSyntaxError("Third byte of chunk type \(PNGChunk.string_rep(chunk_type_buffer)) must have bit 5 set to 0.")
        }

        try png_skip_chunk_data(f, length)
        // ignore unrecognized chunk
        print("unrecognized: \(PNGChunk.string_rep(chunk_type_buffer))")
        return nil
    }
    // all the recognized chunks have valid names so there’s no need to check them

    // check ordering conditions
    try conditions.update(chunk_type)
    if one_of.contains(chunk_type)
    {
        /* — CHUNK DATA READ — */
        let chunk_data = try read_png_buffer(f, length)

        /* — CHUNK CRC32 READ — */
        let stored_chunk_crc = quad_byte_to_int(try read_png_buffer(f, 4))
        var calculated_crc = crc32(0, chunk_type_buffer, 4)
            calculated_crc = crc32(calculated_crc, chunk_data, UInt32(length))
        guard stored_chunk_crc == Int(calculated_crc)
        else
        {
            throw PNGError.DataCorruptionError(PNGChunk.string_rep(chunk_type_buffer))
        }
        return (chunk_type, chunk_data)
    }
    else
    {
        try png_skip_chunk_data(f, length)
        print("skipped: \(chunk_type)")
        return nil
    }
}

public
struct PNGImageHeader
{
    public
    enum ColorType:Int
    {
        case grayscale      = 0,
             rgb            = 2,
             indexed        = 3,
             grayscale_a    = 4,
             rgba           = 6
    }

    public
    let width:Int,
        height:Int,
        bit_depth:Int,
        color_type:ColorType,
        interlace:Bool

    public
    let channels:Int

    fileprivate
    init(_ data:[UInt8]) throws
    {
        guard data.count == 13
        else
        {
            throw PNGError.PNGSyntaxError("Image header chunk does not have the correct length")
        }
        self.width      = quad_byte_to_int(Array(data[0...3]))
        self.height     = quad_byte_to_int(Array(data[4...7]))
        self.bit_depth  = Int(data[8])
        if let color_type = ColorType(rawValue: Int(data[9])) // for some reason guard let doesn’t compile
        {
            self.color_type = color_type
        }
        else
        {
            throw PNGError.PNGSyntaxError("Color type cannot have a value of \(Int(data[9]))")
        }

        /* validate color type */
        let allowed_bit_depths:[Int]
        switch self.color_type
        {
            case .grayscale:
                allowed_bit_depths = [1, 2, 4, 8, 16]
                self.channels = 1
            case .rgb:
                allowed_bit_depths = [8, 16]
                self.channels = 3
            case .indexed:
                allowed_bit_depths = [1, 2, 4, 8]
                self.channels = 1
            case .grayscale_a:
                allowed_bit_depths = [8, 16]
                self.channels = 2
            case .rgba:
                allowed_bit_depths = [8, 16]
                self.channels = 4
        }
        guard allowed_bit_depths.contains(self.bit_depth)
        else
        {
            throw PNGError.PNGSyntaxError("Color type '\(self.color_type)' cannot have a bit depth of \(self.bit_depth)")
        }

        /* validate other fields */
        guard Int(data[10]) == 0
        else
        {
            throw PNGError.PNGSyntaxError("Compression method does not equal 0")
        }
        guard Int(data[11]) == 0
        else
        {
            throw PNGError.PNGSyntaxError("Filter method does not equal 0")
        }
        let interlace   = Int(data[12])
        if interlace == 0
        {
            self.interlace = false
        }
        else if interlace == 1
        {
            self.interlace = true
        }
        else
        {
            throw PNGError.PNGSyntaxError("Interlace method cannot equal \(interlace)")
        }

    }
}

public final
class PNGDataIterator
{
    private
    var f:UnsafeMutablePointer<FILE>

    private
    var conditions = PNGConditions()
    private
    var current_chunk_type:PNGChunkType = .__FIRST__

    private
    let z_iterator:ZIterator
    private
    var the_end:Bool = false
    private
    var defiltered0:[UInt8],
        scanline1:[UInt8]
    private
    let bpp:Int

    public
    let header:PNGImageHeader

    public private(set)
    var palatte:[(r: Int, g: Int, b: Int)]? = nil // not implemented yet — the number of channels is not fixed

    public
    init(path:String, look_for:[PNGChunkType] = [.IDAT]) throws
    {
        if let f = fopen(path, "rb")
        {
            self.f = f
        }
        else
        {
            throw PNGError.FileError
        }

        /* check if it's, you know, actually a PNG */
        var signature:[UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]
        guard (fread(&signature, 1, 8, f) == 8) && (signature == [137, 80, 78, 71, 13, 10, 26, 10]) // compare with PNG signature
        else
        {
            throw PNGError.FiletypeError
        }

        /* read the image header */
        if let (chunk_type, chunk_data) = try png_read_chunk(f: self.f, conditions: &self.conditions, one_of: Set<PNGChunkType>([.IHDR]))
        {
            assert(chunk_type == .IHDR) // this should already be verified from the PNG conditions struct
            self.current_chunk_type = .IHDR
            self.header = try PNGImageHeader(chunk_data)
        }
        else
        {
            throw PNGError.MissingHeaderError
        }

        self.z_iterator = try ZIterator()
        /* initialize the scanline buffers */
        let scanline_bits_n = self.header.width * self.header.channels * self.header.bit_depth
        let scanline_bytes_n = (scanline_bits_n >> 3) + (scanline_bits_n & 7 == 0 ? 0 : 1) + 1 // ceil(scanline_bits_n/8) + 1
        self.defiltered0 = [UInt8](repeating: 0, count: scanline_bytes_n - 1)
        self.scanline1 = [UInt8](repeating: 0, count: scanline_bytes_n)
        self.bpp = max(1, (self.header.channels * self.header.bit_depth) >> 3)

        try self.read_png_info(look_for: look_for)
        print(self.header)
    }

    private
    func read_png_info(look_for:[PNGChunkType]) throws // only ever call this function ONCE!
    {
        assert(self.current_chunk_type != .IDAT)
        let active_chunks:Set<PNGChunkType> = Set(look_for)

        outer_loop: while true
        {
            if let (chunk_type, chunk_data) = try png_read_chunk(f: self.f, conditions: &self.conditions, one_of: active_chunks)
            {
                print(chunk_type)
                self.current_chunk_type = chunk_type

                switch chunk_type
                {
                    case .PLTE:
                        print("indexed-colored pngs are not yet supported")
                    case .IDAT:
                        self.z_iterator.add_input(chunk_data)
                        break outer_loop // we have a check in the conditions preventing IEND from coming early
                    default:
                        print("Reading chunk \(chunk_type.description.1) is not yet supported. tragic")
                }

            }
        }
    }

    private
    func read_scanline() throws
    {
        var empty:Int = self.scanline1.count
        while true
        {
            (empty, self.the_end) = try self.z_iterator.get_output(&self.scanline1, empty: empty)
            /* if the output is not full, add more input */
            if empty != 0
            {
                guard !self.the_end
                else
                {
                    throw PNGError.PrematureEOSError
                }
                /* read another IDAT chunk */
                let (chunk_type, chunk_data) = try png_read_chunk(f: self.f, conditions: &self.conditions, one_of: Set<PNGChunkType>([.IDAT]))!
                // PNGConditions is guaranteeing this

                assert(chunk_type == .IDAT) // this should already be verified from the PNG conditions struct
                self.current_chunk_type = .IDAT
                self.z_iterator.add_input(chunk_data)

            }
            else
            {
                break
            }
        }
    }

    public
    func next(_ n:Int) throws -> [UInt8]?
    {
        guard self.current_chunk_type == .IDAT
        else
        {
            print("attempt to read without .IDAT flag set, please call `PNGDataIterator.init()` with `.IDAT` in the `look_for` field to read image pixels")
            return nil
        }
        if !self.the_end
        {
            try self.read_scanline()
            let filter = self.scanline1[0]
            var defiltered1 = Array(self.scanline1.dropFirst(1))
            switch filter
            {
                case 0:
                    break
                case 1:
                    PNGDataIterator.filter_sub(&defiltered1, bpp: self.bpp)
                case 2:
                    PNGDataIterator.filter_up(&defiltered1, defiltered0: self.defiltered0)
                case 3:
                    PNGDataIterator.filter_average(&defiltered1, defiltered0: self.defiltered0, bpp: self.bpp)
                case 4:
                    PNGDataIterator.filter_paeth(&defiltered1, defiltered0: self.defiltered0, bpp: self.bpp)
                default:
                    break // won’t happen
            }
            self.defiltered0 = defiltered1
            return defiltered1
        }
        else
        {
            return nil
        }
    }

    private static
    func filter_sub(_ defiltered1:inout [UInt8], bpp:Int)
    {
        for i in bpp..<defiltered1.count
        {
            defiltered1[i] = defiltered1[i] &+ defiltered1[i - bpp]
        }
    }

    private static
    func filter_up(_ defiltered1:inout [UInt8], defiltered0:[UInt8])
    {
        for i in 0..<defiltered1.count
        {
            defiltered1[i] = defiltered1[i] &+ defiltered0[i]
        }
    }

    private static
    func filter_average(_ defiltered1:inout [UInt8], defiltered0:[UInt8], bpp:Int)
    {
        for i in 0..<bpp
        {
            defiltered1[i] = defiltered1[i] &+ defiltered0[i] >> 2
        }
        for i in bpp..<defiltered1.count
        {
            defiltered1[i] = defiltered1[i] &+ UInt8((UInt16(defiltered1[i - bpp]) + UInt16(defiltered0[i])) >> 2) // the second part will never overflow because of the right shift
        }
    }

    private static
    func filter_paeth(_ defiltered1:inout [UInt8], defiltered0:[UInt8], bpp:Int)
    {
        for i in 0..<bpp
        {
            defiltered1[i] = defiltered1[i] &+ PNGDataIterator.paeth(0, defiltered0[i], 0)
        }
        for i in bpp..<defiltered1.count
        {
            defiltered1[i] = defiltered1[i] &+ PNGDataIterator.paeth(defiltered1[i - bpp], defiltered0[i], defiltered0[i - bpp])
        }
    }

    private static
    func paeth(_ a:UInt8, _ b:UInt8, _ c:UInt8) -> UInt8
    {
        let a16 = Int16(a),
            b16 = Int16(b),
            c16 = Int16(c)
        let p:Int16 = a16 + b16 - c16 // do b - c first to avoid overflow and reduce the number of UInt16 casts
        let pa = abs(p - a16),
            pb = abs(p - b16),
            pc = abs(p - c16)

        if pa <= pb && pa <= pc
        {
            return a
        }
        else
        {
            return pb <= pc ? b : c
        }
    }

    deinit
    {
        fclose(self.f)
        print("file closed")
    }
}

fileprivate
class ZIterator
{
    private
    var stream:z_stream_s

    private
    var input:[UInt8] = []

    enum DecompressionError:Error
    {
        case StreamError
        case MissingDictionaryError
        case DataError
        case MemoryError
    }

    init() throws
    {
        self.stream = z_stream()

        /* allocate inflate state */
        self.stream.zalloc = nil
        self.stream.zfree = nil
        self.stream.opaque = nil
        self.stream.avail_in = 0
        self.stream.next_in = nil
        guard inflateInit(&self.stream) == Z_OK
        else
        {
            throw DecompressionError.StreamError
        }
    }

    deinit
    {
        print("zstream ended")
        inflateEnd(&self.stream)
    }

    func add_input(_ input:[UInt8])
    {
        self.input = input
        self.stream.avail_in = UInt32(self.input.count)
        self.stream.next_in = UnsafeMutablePointer<UInt8>(mutating: self.input) // does this maintain the reference??
    }

    func get_output(_ output_buffer:inout [UInt8], empty:Int) throws -> (empty:Int, the_end:Bool)
    {
        var inflate_status:Int32 = Z_OK
        self.stream.avail_out = UInt32(empty)
        self.stream.next_out = UnsafeMutablePointer<UInt8>(mutating: output_buffer).advanced(by: output_buffer.count - empty)
        inflate_status = inflate(&stream, Z_NO_FLUSH)
        assert(inflate_status != Z_STREAM_ERROR) // this should never happen
        switch inflate_status
        {
            case Z_NEED_DICT:
                throw DecompressionError.MissingDictionaryError
            case Z_DATA_ERROR:
                throw DecompressionError.DataError
            case Z_MEM_ERROR:
                throw DecompressionError.MemoryError
            default:
                break
        }
        return (Int(self.stream.avail_out), inflate_status == Z_STREAM_END)
    }
}

/* If you are wondering why this function exists, it’s because Swift doesn’t know how to import C function macros yet. */
private
func inflateInit(_ strm:inout z_stream_s) -> Int32
{
    return inflateInit_(&strm, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
}
