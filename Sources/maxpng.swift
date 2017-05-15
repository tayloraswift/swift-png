import Zlib
import Glibc

typealias FilePointer = UnsafeMutablePointer<FILE>

public
enum PNGReadError:Error
{
    case FileError(String),
         FiletypeError,
         IncompleteChunkError,
         UnexpectedCriticalChunkError(String),
         PNGSyntaxError(String),
         DataCorruptionError(String),

         DuplicateChunkError(PNGChunkType),
         ChunkOrderingError(PNGChunkType),
         MissingHeaderError,
         PrematureEOSError,
         PrematureIENDError
}

public
enum PNGWriteError:Error
{
    case FileWriteError,
         DimemsionError,
         InterlaceDimensionError
}

public
enum PNGDecompressionError:Error
{
    case StreamError
    case MissingDictionaryError
    case DataError
    case MemoryError
}

public
enum PNGCompressionError:Error
{
    case StreamError
}

public
struct RGBA<Pixel:UnsignedInteger>:Equatable, CustomStringConvertible
{
    public
    let r:Pixel,
        g:Pixel,
        b:Pixel,
        a:Pixel

    public
    var description:String
    {
        return "(\(self.r), \(self.g), \(self.b), \(self.a))"
    }

    public
    init(_ r:Pixel, _ g:Pixel, _ b:Pixel, _ a:Pixel)
    {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    public static
    func == (_ lhs:RGBA<Pixel>, _ rhs:RGBA<Pixel>) -> Bool
    {
        return lhs.r == rhs.r && lhs.g == rhs.g && lhs.b == rhs.b && lhs.a == rhs.a
    }
}

struct PNGConditions
{
    private(set)
    var seen = Set<PNGChunkType>()
    private(set)
    var last_valid_chunk:PNGChunkType = PNGChunkType.__FIRST__

    mutating
    func update(_ chunk_type:PNGChunkType) throws
    {
        if self.last_valid_chunk == .__FIRST__ && chunk_type != .IHDR
        {
            throw PNGReadError.MissingHeaderError
        }
        else if self.last_valid_chunk == .IEND
        {
            throw PNGReadError.PrematureIENDError
        }
        if chunk_type == .IEND && !self.seen.contains(.IDAT)
        // separated from the switch block because it doesn’t work right for some reason
        {
            throw PNGReadError.PrematureIENDError
        }

        switch chunk_type
        {
        // PLTE must come before bKGD, hIST, and tRNS
        case .PLTE:
            if self.seen.contains(.bKGD) || self.seen.contains(.hIST) || self.seen.contains(.tRNS)
            {
                throw PNGReadError.ChunkOrderingError(chunk_type)
            }
            fallthrough
        // these chunks must occur before PLTE
        case        .cHRM, .gAMA, .iCCP, .sBIT, .sRGB:
            if self.seen.contains(.PLTE)
            {
                throw PNGReadError.ChunkOrderingError(chunk_type)
            }
            fallthrough

        // these chunks must occur before IDAT
        case .PLTE, .cHRM, .gAMA, .iCCP, .sBIT, .sRGB, .bKGD, .hIST, .tRNS, .pHYs, .sPLT:
            if self.seen.contains(.IDAT)
            {
                throw PNGReadError.ChunkOrderingError(chunk_type)
            }
            fallthrough


        // these chunks cannot duplicate
        case .IHDR, .PLTE, .IEND, .cHRM, .gAMA, .iCCP, .sBIT, .sRGB, .bKGD, .hIST, .tRNS, .pHYs, .sPLT, .tIME:
            if self.seen.contains(chunk_type)
            {
                throw PNGReadError.DuplicateChunkError(chunk_type)
            }

        // IDAT blocks much be consecutive
        case .IDAT:
            if self.last_valid_chunk != .IDAT && self.seen.contains(.IDAT)
            {
                throw PNGReadError.ChunkOrderingError(chunk_type)
            }
        default:
            break
        }
        self.last_valid_chunk = chunk_type
        self.seen.insert(chunk_type)
    }
}

public
enum PNGChunkType:String
{
    case __FIRST__,
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
         zTXt,

         __INTERRUPTOR__

    init?(buffer:[UInt8])
    {
        self.init(rawValue: String(buffer.flatMap(UnicodeScalar.init).map(Character.init)))
    }
}

func buffer_to_string(_ buffer:[UInt8]) -> String // this function only used for error messages
{
    return String(buffer.flatMap(UnicodeScalar.init).map(Character.init))
}

func quad_byte_to_int(_ buffer:[UInt8]) -> Int
{
    return Int(UInt32(bigEndian: buffer.withUnsafeBufferPointer
    {
        ($0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0 })
    }.pointee))
}

func int_to_quad_byte(_ integer:UInt32) -> [UInt8]
{
    return [UInt8(integer >> 24 & 0xFF),
            UInt8(integer >> 16 & 0xFF),
            UInt8(integer >> 8  & 0xFF),
            UInt8(integer       & 0xFF)]
}

func read_png_buffer(_ f:FilePointer, _ length:Int) throws -> [UInt8]
{
    var buffer = [UInt8](repeating: 0, count: length)
    guard fread(&buffer, 1, length, f) == length
    else
    {
        throw PNGReadError.IncompleteChunkError
    }
    return buffer
}

func skip_png_buffer(_ f:FilePointer, _ length:Int) throws
{
    if length <= 128 // most regulated-length png chunks are shorter than 128 bytes
    {
        let _ = try read_png_buffer(f, length + 4) // 4 bytes for CRC32
    }
    else
    {
        fseek(f, length, SEEK_CUR)
        let _ = try read_png_buffer(f, 4) // read a throwaway buffer, also corresponds to CRC32
    }
}

func write_png_buffer(_ f:FilePointer, buffer:[UInt8]) throws
{
    guard fwrite(buffer, 1, buffer.count, f) == buffer.count
    else
    {
        throw PNGWriteError.FileWriteError
    }
}

func png_read_chunk(f:FilePointer, conditions:inout PNGConditions, one_of:Set<PNGChunkType>)
throws -> (chunk_type:PNGChunkType, chunk_data:[UInt8])?
{
    /* — CHUNK LENGTH READ — */
    let length:Int = quad_byte_to_int(try read_png_buffer(f, 4))

    /* — CHUNK TYPE READ AND VALIDATION — */
    let chunk_type_buffer = try read_png_buffer(f, 4)
    guard let chunk_type = PNGChunkType(buffer: chunk_type_buffer)
    else
    {
        guard (chunk_type_buffer[0] & (1 << 5)) != 0
        else
        {
            throw PNGReadError.UnexpectedCriticalChunkError(buffer_to_string(chunk_type_buffer))
        }
        guard (chunk_type_buffer[2] & (1 << 5)) == 0
        else
        {
            throw PNGReadError.PNGSyntaxError("Third byte of chunk type \(buffer_to_string(chunk_type_buffer)) must have bit 5 set to 0.")
        }

        try skip_png_buffer(f, length)
        // ignore unrecognized chunk
        fputs("unrecognized: \(buffer_to_string(chunk_type_buffer))", stderr)
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
        let stored_chunk_crc:UInt = UInt(quad_byte_to_int(try read_png_buffer(f, 4)))
        var calculated_crc:UInt   = crc32(0, chunk_type_buffer, 4)
            calculated_crc        = crc32(calculated_crc, chunk_data, UInt32(length))
        guard stored_chunk_crc == calculated_crc
        else
        {
            throw PNGReadError.DataCorruptionError(chunk_type.rawValue)
        }
        return (chunk_type, chunk_data)
    }
    else
    {
        try skip_png_buffer(f, length)
        //print("skipped: \(chunk_type)")
        return nil
    }
}

func png_write_chunk(f:FilePointer, chunk_data:[UInt8], chunk_type:PNGChunkType) throws
{
    try write_png_buffer(f, buffer: int_to_quad_byte(UInt32(chunk_data.count))) // length section
    let chunk_type_buffer:[UInt8] = [UInt8](chunk_type.rawValue.utf8)
    assert(chunk_type_buffer.count == 4)
    try write_png_buffer(f, buffer: chunk_type_buffer) // chunk type section
    try write_png_buffer(f, buffer: chunk_data) // chunk data section
    var calculated_crc:UInt = crc32(0, chunk_type_buffer, 4)
        calculated_crc      = crc32(calculated_crc, chunk_data, UInt32(chunk_data.count))
    try write_png_buffer(f, buffer: int_to_quad_byte(UInt32(calculated_crc))) // crc section // this Int() cast only works because crc is a 32 bit value padded to 64 bits
}

public
struct PNGHeader:CustomStringConvertible
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

    public
    let sub_dimensions:[(width:Int, height:Int)],
        sub_data_ranges:[Range<Int>]

    let sub_striders:[(u:StrideTo<Int>, v:StrideTo<Int>)],
        sub_array_bounds:[(i:Int, j:Int)],
        bpp:Int,
        interlaced_data_size:Int,
        noninterlaced_data_size:Int

    static
    let signature:[UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]

    public
    var description:String
    {
        return "<PNG header>{image dimensions: \(self.width) × \(self.height), bit depth: \(self.bit_depth), color: \(self.color_type), interlaced: \(self.interlace)}"
    }

    public
    init(width:Int, height:Int, bit_depth:Int, color_type:ColorType, interlace:Bool) throws
    {
        self.width = width
        self.height = height
        self.bit_depth = bit_depth
        self.color_type = color_type
        self.interlace = interlace

        /* validate color type */
        let allowed_bit_depths:[Int],
            channels:Int
        switch self.color_type
        {
        case .grayscale:
            allowed_bit_depths = [1, 2, 4, 8, 16]
            channels = 1
        case .rgb:
            allowed_bit_depths = [8, 16]
            channels = 3
        case .indexed:
            allowed_bit_depths = [1, 2, 4, 8]
            channels = 1
        case .grayscale_a:
            allowed_bit_depths = [8, 16]
            channels = 2
        case .rgba:
            allowed_bit_depths = [8, 16]
            channels = 4
        }
        guard allowed_bit_depths.contains(bit_depth)
        else
        {
            throw PNGReadError.PNGSyntaxError("Color type '\(self.color_type)' cannot have a bit depth of \(self.bit_depth)")
        }

        self.bpp      = max(1, (channels * bit_depth) >> 3)
        self.channels = channels

        /* calculate size of interlaced subimages, even if the image is not interlaced (to help the deinterlace() function) */
        // 0: (w + 7) >> 3 , (h + 7) >> 3
        // 1: (w + 3) >> 3 , (h + 7) >> 3
        // 2: (w + 3) >> 2 , (h + 3) >> 3
        // 3: (w + 1) >> 2 , (h + 3) >> 2
        // 4: (w + 1) >> 1 , (h + 1) >> 2
        // 5: (w) >> 1     , (h + 1) >> 1
        // 6: (w)          , (h) >> 1
        self.sub_dimensions = [ (width: (self.width  + 7) >> 3, height: (self.height + 7) >> 3),
                                (width: (self.width  + 3) >> 3, height: (self.height + 7) >> 3),
                                (width: (self.width  + 3) >> 2, height: (self.height + 3) >> 3),
                                (width: (self.width  + 1) >> 2, height: (self.height + 3) >> 2),
                                (width: (self.width  + 1) >> 1, height: (self.height + 1) >> 2),
                                (width:  self.width       >> 1, height: (self.height + 1) >> 1),
                                (width:  self.width       >> 0, height:  self.height      >> 1),
                                (width:  self.width           , height:  self.height          )]
        self.sub_striders   = [ (u: stride(from: 0, to: self.width, by: 8), v: stride(from: 0, to: self.height, by: 8)),
                                (u: stride(from: 4, to: self.width, by: 8), v: stride(from: 0, to: self.height, by: 8)),
                                (u: stride(from: 0, to: self.width, by: 4), v: stride(from: 4, to: self.height, by: 8)),
                                (u: stride(from: 2, to: self.width, by: 4), v: stride(from: 0, to: self.height, by: 4)),
                                (u: stride(from: 0, to: self.width, by: 2), v: stride(from: 2, to: self.height, by: 4)),
                                (u: stride(from: 1, to: self.width, by: 2), v: stride(from: 0, to: self.height, by: 2)),
                                (u: stride(from: 0, to: self.width, by: 1), v: stride(from: 1, to: self.height, by: 2))]
        self.sub_array_bounds = self.sub_dimensions.map
        {
            let scanline_bits_n:Int  = $0.width * channels * bit_depth
            let scanline_bytes_n:Int = (scanline_bits_n >> 3) + (scanline_bits_n & 7 == 0 ? 0 : 1)  // ceil(scanline_bits_n/8)
            return (i: $0.height, j: scanline_bytes_n)
        }

        var accumulator:Int = 0
        self.sub_data_ranges = self.sub_array_bounds.dropLast().map
        {
            let upper:Int = accumulator + $0.i * $0.j
            let range:Range<Int> = accumulator ..< upper
            accumulator = upper
            return range
        }

        self.interlaced_data_size = accumulator
        self.noninterlaced_data_size = self.sub_array_bounds[7].i * self.sub_array_bounds[7].j
    }

    init(_ data:[UInt8]) throws
    {
        guard data.count == 13
        else
        {
            throw PNGReadError.PNGSyntaxError("Image header chunk does not have the correct length")
        }

        guard let color_type = ColorType(rawValue: Int(data[9]))
        else
        {
            throw PNGReadError.PNGSyntaxError("Color type cannot have a value of \(Int(data[9]))")
        }

        /* validate other fields */
        guard Int(data[10]) == 0
        else
        {
            throw PNGReadError.PNGSyntaxError("Compression method does not equal 0")
        }
        guard Int(data[11]) == 0
        else
        {
            throw PNGReadError.PNGSyntaxError("Filter method does not equal 0")
        }
        let interlace:Bool
        let interlace_i = Int(data[12]) // TODO: turn this into a switch case
        if interlace_i == 0
        {
            interlace = false
        }
        else if interlace_i == 1
        {
            interlace = true
        }
        else
        {
            throw PNGReadError.PNGSyntaxError("Interlace method cannot equal \(interlace_i)")
        }

        try self.init(width     : quad_byte_to_int(Array(data[0...3])),
                      height    : quad_byte_to_int(Array(data[4...7])),
                      bit_depth : Int(data[8]),
                      color_type: color_type,
                      interlace : interlace)
    }

    func write() -> [UInt8]
    {
        var bytes:[UInt8] = int_to_quad_byte(UInt32(self.width))        // [0:3]
        bytes.reserveCapacity(12)
        bytes.append(contentsOf: int_to_quad_byte(UInt32(self.height))) // [4:7]
        bytes.append(UInt8(self.bit_depth))                             // [8]
        bytes.append(UInt8(self.color_type.rawValue))                   // [9]
        bytes.append(0)                                                 // [10] = 0
        bytes.append(0)                                                 // [11] = 0
        bytes.append(self.interlace ? 1 : 0)                            // [12]
        return bytes
    }
}

func paeth(_ a:UInt8, _ b:UInt8, _ c:UInt8) -> UInt8
{
    let a16 = Int16(a),
        b16 = Int16(b),
        c16 = Int16(c)
    let p:Int16 = a16 + b16 - c16
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

public final
class PNGEncoder
{
    private
    var stream:FilePointer

    private
    var reference_line:[UInt8],
        chunk_data:[UInt8]

    private
    var chunk_capacity_remaining:Int

    private
    let header:PNGHeader,
        z_iterator:ZDeflator

    public
    init (path:String, header:PNGHeader, chunk_size:Int = 1 << 16) throws
    {
        if let stream = fopen(path, "wb")
        {
            self.stream = stream
        }
        else
        {
            throw PNGReadError.FileError(path)
        }

        self.chunk_capacity_remaining = chunk_size

        self.header         = header
        self.z_iterator     = try ZDeflator()
        self.reference_line = [UInt8](repeating: 0, count: header.sub_array_bounds[7].j)
        self.chunk_data     = [UInt8](repeating: 0, count: chunk_size)
    }

    deinit
    {
        fclose(self.stream)
    }

    public
    func initialize() throws
    {
        try write_png_buffer(self.stream, buffer: PNGHeader.signature)
        try png_write_chunk(f: self.stream, chunk_data: self.header.write(), chunk_type: .IHDR)
    }

    public
    func add_scanline(_ src:[UInt8]) throws
    {
        guard src.count == reference_line.count
        else
        {
            throw PNGWriteError.DimemsionError
        }

        var filter_data = [[UInt8]](repeating: [0] + src, count: 5)

        PNGEncoder.filter_sub    (&filter_data[1], bpp: self.header.bpp)
        PNGEncoder.filter_up     (&filter_data[2], previous_line: self.reference_line)
        PNGEncoder.filter_average(&filter_data[3], previous_line: self.reference_line, bpp: self.header.bpp)
        PNGEncoder.filter_paeth  (&filter_data[4], previous_line: self.reference_line, bpp: self.header.bpp)

        self.reference_line = src

        /* pick the most effective filter */
        let scores:[Int] = filter_data.map(PNGEncoder.score)
        var min_filter:Int = 0
        var min_score:Int = Int.max
        for (i, score) in scores.enumerated()
        {
            if score < min_score
            {
                min_score = score
                min_filter = i
            }
        }

        filter_data[min_filter][0] = UInt8(min_filter)
        self.z_iterator.add_input(filter_data[min_filter])

        try self.compress_scanline(finish: false)
    }

    private
    func compress_scanline(finish:Bool) throws
    {
        var stream_exhausted:Bool = false
        repeat
        {
            try self.chunk_data.withUnsafeMutableBufferPointer
            {
                let dest_base:UnsafeMutablePointer<UInt8> = $0.baseAddress! + ($0.count - self.chunk_capacity_remaining)
                let dest = UnsafeMutableBufferPointer<UInt8>(start: dest_base, count: self.chunk_capacity_remaining)
                self.z_iterator.set_output(dest: dest)
                // like with the Inflator, the above is tracked internally by the zstream, but we can’t guarantee
                // the stability of the underlying `chunk_data` buffer so we recalculate the destination each cycle.

                self.chunk_capacity_remaining = Int(try self.z_iterator.get_output(sentinel: &stream_exhausted, finish: finish))
                assert(!stream_exhausted || finish) // the_end cannot come yet
            }
        } while try self.attempt_emit_idat_chunk()
        assert(stream_exhausted || !finish)
    }

    public
    func finish() throws
    {
        try self.compress_scanline(finish: true)

        if self.chunk_capacity_remaining != self.chunk_data.count // meaning, there is still data in the buffer
        {
            try png_write_chunk(f: self.stream, chunk_data: [UInt8](self.chunk_data.dropLast(self.chunk_capacity_remaining)), chunk_type: .IDAT)
        }
        try png_write_chunk(f: self.stream, chunk_data: [], chunk_type: .IEND)
    }

    private
    func attempt_emit_idat_chunk() throws -> Bool
    {
        if self.chunk_capacity_remaining == 0
        {
            /* emit chunk */
            try png_write_chunk(f: self.stream, chunk_data: self.chunk_data, chunk_type: .IDAT)
            self.chunk_capacity_remaining = self.chunk_data.count
            return true
        }
        else
        {
            return false
        }
    }

    /* these are literally exactly the same as the defilter functions except backwards */
    private static
    func filter_sub(_ buffer:inout [UInt8], bpp:Int)
    {
        for i in ((1 + bpp)..<buffer.count).reversed()
        {
            buffer[i] = buffer[i] &- buffer[i - bpp]
        }
    }

    private static
    func filter_up(_ buffer:inout [UInt8], previous_line:[UInt8])
    {
        for i in 1..<buffer.count // we do not need to reverse here
        {
            buffer[i] = buffer[i] &- previous_line[i - 1]
        }
    }

    private static
    func filter_average(_ buffer:inout [UInt8], previous_line:[UInt8], bpp:Int)
    {
        for i in ((1 + bpp)..<buffer.count).reversed()
        {
            buffer[i] = buffer[i] &- UInt8((UInt16(buffer[i - bpp]) + UInt16(previous_line[i - 1])) >> 1) // the second part will never overflow because of the right shift
        }
        for i in 1..<(1 + bpp) // we do not need to reverse here
        {
            buffer[i] = buffer[i] &- previous_line[i - 1] >> 1
        }
    }

    private static
    func filter_paeth(_ buffer:inout [UInt8], previous_line:[UInt8], bpp:Int)
    {

        for i in ((1 + bpp)..<buffer.count).reversed()
        {
            buffer[i] = buffer[i] &- paeth(buffer[i - bpp], previous_line[i - 1], previous_line[i - 1 - bpp])
        }
        for i in 1..<(1 + bpp)
        {
            buffer[i] = buffer[i] &- paeth(0, previous_line[i - 1], 0)
        }
    }

    private static
    func score(_ filtered:[UInt8]) -> Int
    {
        guard filtered.count > 0
        else
        {
            return 0
        }
        var changes:Int = 0
        var last:UInt8 = filtered[0]
        for byte in filtered.dropFirst()
        {
            changes += byte == last ? 0 : 1
            last = byte
        }
        return changes
    }
}

struct ScanlineIterator
{
    private
    let sub_array_bounds:[(i:Int, j:Int)],
        interlace:Bool

    private
    var interlace_level:Int = 0,
        scanlines_remaining:Int,
        use_zero_line:UInt8 = 0b10

    private(set)
    var bytes_per_scanline:Int

    var first_scanline:Bool
    {
        return self.use_zero_line != 0
    }

    init(header:PNGHeader)
    {
        if header.interlace
        {
            self.scanlines_remaining = header.sub_array_bounds[0].i
            self.bytes_per_scanline  = header.sub_array_bounds[0].j
            self.interlace = true
        }
        else
        {
            self.scanlines_remaining = header.sub_array_bounds[7].i
            self.bytes_per_scanline  = header.sub_array_bounds[7].j
            self.interlace = false
        }
        self.sub_array_bounds = header.sub_array_bounds
    }

    mutating
    func update_scanline_size() -> Bool // return false if iteration has reached the end
    {
        guard self.scanlines_remaining > 0
        else
        {
            self.interlace_level    += 1
            guard self.interlace && self.interlace_level < 7
            else
            {
                return false
            }

            self.scanlines_remaining = self.sub_array_bounds[self.interlace_level].i - 1
            self.bytes_per_scanline  = self.sub_array_bounds[self.interlace_level].j
            self.use_zero_line       = 0b01
            return true
        }

        self.use_zero_line >>= 1 // the first_scanline flag must be set *after* the first call to this function
        self.scanlines_remaining -= 1
        return true
    }

    func make_zero_line() -> [UInt8]
    {
        return [UInt8](repeating: 0, count: self.sub_array_bounds[self.interlace ? 6 : 7].j) // the most zeros we will ever need
    }
}

struct Decoder
{
    private
    var conditions = PNGConditions(),
        current_chunk_type:PNGChunkType = .__FIRST__

    private
    var z_iterator:ZInflator,
        stream_exhausted:Bool = false

    let header:PNGHeader

    /*
    public private(set)
    var palatte:[(r: Int, g: Int, b: Int)]? = nil // not implemented yet — the number of channels is not fixed
    */

    public
    init(stream:FilePointer, look_for:[PNGChunkType] = [.IDAT]) throws
    {
        /* check if it's, you know, actually a PNG */
        guard (try read_png_buffer(stream, 8) == PNGHeader.signature) // compare with PNG signature
        else
        {
            throw PNGReadError.FiletypeError
        }

        /* read the image header */
        if let (chunk_type, chunk_data) = try png_read_chunk(f: stream, conditions: &self.conditions, one_of: Set<PNGChunkType>([.IHDR]))
        {
            assert(chunk_type == .IHDR) // this should already be verified from the PNG conditions struct
            self.current_chunk_type = .IHDR
            self.header = try PNGHeader(chunk_data)
        }
        else
        {
            throw PNGReadError.MissingHeaderError
        }

        self.z_iterator = try ZInflator()

        try self.read_png_info(stream: stream, look_for: look_for)
    }

    private mutating
    func read_png_info(stream:FilePointer, look_for:[PNGChunkType]) throws // only ever call this function ONCE!
    {
        assert(self.current_chunk_type != .IDAT)
        var active_chunks:Set<PNGChunkType> = Set(look_for)
        active_chunks.insert(.IEND) // we must always be vigilant

        outer_loop: while true
        {
            if let (chunk_type, chunk_data) = try png_read_chunk(f: stream, conditions: &self.conditions, one_of: active_chunks)
            {
                self.current_chunk_type = chunk_type

                switch chunk_type
                {
                    case .PLTE:
                        fputs("indexed-colored pngs are not yet supported", stderr)
                    case .IDAT:
                        self.z_iterator.add_input(chunk_data)
                        break outer_loop // we have a check in the conditions preventing IEND from coming early
                    case .IEND:
                        break outer_loop
                    default:
                        fputs("Reading chunk \(chunk_type) is not yet supported. tragic", stderr)
                }
            }
        }
    }

    mutating
    func decompress_scanline(stream:FilePointer, dest:UnsafeMutableBufferPointer<UInt8>) throws -> UInt8
    {
        var filter_byte:UInt8 = 0
        while true
        {
            if let output_byte:UInt8 = try self.z_iterator.get_output_byte(sentinel: &self.stream_exhausted)
            {
                filter_byte = output_byte
                break;
            }

            guard !self.stream_exhausted
            else
            {
                throw PNGReadError.PrematureEOSError
            }

            // if the inflator is out of input
            guard let (_, chunk_data) = try png_read_chunk(f: stream, conditions: &self.conditions, one_of: Set<PNGChunkType>([.IDAT]))
            else
            {
                // if something besides an IDAT chunk shows up, that’s an invalid PNGChunkType
                throw PNGReadError.ChunkOrderingError(.__INTERRUPTOR__)
            }
            self.z_iterator.add_input(chunk_data)
        }

        self.z_iterator.set_output(dest: dest)
        while try self.z_iterator.get_output_bytes(sentinel: &self.stream_exhausted) > 0
        {
            guard !self.stream_exhausted
            else
            {
                throw PNGReadError.PrematureEOSError
            }

            // if the inflator is out of input
            guard let (_, chunk_data) = try png_read_chunk(f: stream, conditions: &self.conditions, one_of: Set<PNGChunkType>([.IDAT]))
            else
            {
                // if something besides an IDAT chunk shows up, that’s an invalid PNGChunkType
                throw PNGReadError.ChunkOrderingError(.__INTERRUPTOR__)
            }
            self.z_iterator.add_input(chunk_data)
        }

        return filter_byte
    }

    // make NO assumptions about the `.count` property of the reference line;
    // it is often greater than the size of the actual data
    func defilter_scanline<ReferenceLine:Collection>(dest:UnsafeMutableBufferPointer<UInt8>, reference:ReferenceLine, filter:UInt8)
    where ReferenceLine.Iterator.Element == UInt8, ReferenceLine.Index == Int
    {
        switch filter
        {
        case 0:
            break
        case 1:
            Decoder.defilter_sub    (dest, bpp: self.header.bpp)
        case 2:
            Decoder.defilter_up     (dest, previous_line: reference)
        case 3:
            Decoder.defilter_average(dest, previous_line: reference, bpp: self.header.bpp)
        case 4:
            Decoder.defilter_paeth  (dest, previous_line: reference, bpp: self.header.bpp)
        default:
            break // won’t happen
        }
    }

    private static
    func defilter_sub(_ buffer:UnsafeMutableBufferPointer<UInt8>, bpp:Int)
    {
        for i in bpp..<buffer.count
        {
            buffer[i] = buffer[i] &+ buffer[i - bpp]
        }
    }

    private static
    func defilter_up<ReferenceLine:Collection>(_ buffer:UnsafeMutableBufferPointer<UInt8>, previous_line:ReferenceLine)
    where ReferenceLine.Iterator.Element == UInt8, ReferenceLine.Index == Int
    {
        for i in 0..<buffer.count
        {
            buffer[i] = buffer[i] &+ previous_line[i]
        }
    }

    private static
    func defilter_average<ReferenceLine:Collection>(_ buffer:UnsafeMutableBufferPointer<UInt8>, previous_line:ReferenceLine, bpp:Int)
    where ReferenceLine.Iterator.Element == UInt8, ReferenceLine.Index == Int
    {
        for i in 0..<bpp
        {
            buffer[i] = buffer[i] &+ previous_line[i] >> 1
        }
        for i in bpp..<buffer.count
        {
            buffer[i] = buffer[i] &+ UInt8((UInt16(buffer[i - bpp]) + UInt16(previous_line[i])) >> 1) // the second part will never overflow because of the right shift
        }
    }

    private static
    func defilter_paeth<ReferenceLine:Collection>(_ buffer:UnsafeMutableBufferPointer<UInt8>, previous_line:ReferenceLine, bpp:Int)
    where ReferenceLine.Iterator.Element == UInt8, ReferenceLine.Index == Int
    {
        for i in 0..<bpp
        {
            buffer[i] = buffer[i] &+ paeth(0, previous_line[i], 0)
        }
        for i in bpp..<buffer.count
        {
            buffer[i] = buffer[i] &+ paeth(buffer[i - bpp], previous_line[i], previous_line[i - bpp])
        }
    }
}

public final
class PNGDecoder
{
    private
    var stream:FilePointer

    private
    var decoder:Decoder,
        scanline_iter:ScanlineIterator

    private
    var reference_line:[UInt8] = []
    private
    let zero_line:[UInt8]

    public
    var header:PNGHeader { return self.decoder.header }

    public
    init(path:String, look_for:[PNGChunkType] = [.IDAT]) throws
    {
        if let stream:FilePointer = fopen(path, "rb")
        {
            self.stream = stream
        }
        else
        {
            throw PNGReadError.FileError(path)
        }

        self.decoder        = try Decoder(stream: stream, look_for: look_for)
        self.scanline_iter  = ScanlineIterator(header: self.decoder.header)
        self.zero_line      = self.scanline_iter.make_zero_line()
    }

    deinit
    {
        fclose(self.stream)
    }

    public
    func next_scanline() throws -> [UInt8]?
    {
        guard self.scanline_iter.update_scanline_size()
        else
        {
            return nil
        }

        var buffer:[UInt8] = [UInt8](repeating: 0, count: self.scanline_iter.bytes_per_scanline)
        try buffer.withUnsafeMutableBufferPointer
        {
            (bp) in

            let filter:UInt8 = try self.decoder.decompress_scanline(stream: self.stream, dest: bp)
            if self.scanline_iter.first_scanline
            {
                self.zero_line.withUnsafeBufferPointer
                {
                    self.decoder.defilter_scanline(dest: bp, reference: $0, filter: filter)
                }
            }
            else
            {
                self.reference_line.withUnsafeBufferPointer
                {
                    self.decoder.defilter_scanline(dest: bp, reference: $0, filter: filter)
                }
            }
        }

        self.reference_line = buffer
        return buffer
    }
}

public
func rgba32(raw_data:[UInt8], header:PNGHeader) -> [RGBA<UInt8>]?
{
    guard header.bit_depth <= 8
    else
    {
        return nil
    }

    guard header.color_type != .indexed
    else
    {
        fputs("Normalizing indexed PNGs is unsupported\n", stderr)
        return nil
    }

    let output:[RGBA<UInt8>]
    if header.bit_depth < 8 // channels is guaranteed to be 1
    {
        let quantum:UInt8 = UInt8.max / (UInt8.max >> (8 - UInt8(header.bit_depth)))
        output = stride(from: 0, to: raw_data.count << 3, by: header.bit_depth).map
        {
            let value:UInt8 = quantum * bitval_extract(bit_index: $0, bit_depth: header.bit_depth, source: raw_data)
            return RGBA(value, value, value, UInt8.max)
        }
    }
    else
    {
        switch header.color_type
        {
        case .grayscale:
            output = raw_data.map{ value in RGBA(value, value, value, UInt8.max) }
        case .grayscale_a:
            output = stride(from: 0, to: raw_data.count, by: 2).map
            {
                let value:UInt8 = raw_data[$0]
                return RGBA(value, value, value, raw_data[$0 + 1])
            }
        case .rgb:
            output = stride(from: 0, to: raw_data.count, by: 3).map
            {
                let r:UInt8 = raw_data[$0    ],
                    g:UInt8 = raw_data[$0 + 1],
                    b:UInt8 = raw_data[$0 + 2]
                return RGBA(r, g, b, UInt8.max)
            }
        case .rgba:
            output = stride(from: 0, to: raw_data.count, by: 4).map
            {
                let r:UInt8 = raw_data[$0    ],
                    g:UInt8 = raw_data[$0 + 1],
                    b:UInt8 = raw_data[$0 + 2],
                    a:UInt8 = raw_data[$0 + 3]
                return RGBA(r, g, b, a)
            }
        case .indexed:
            return nil // should never reach here
        }
    }

    return output
}

public
func rgba64(raw_data:[UInt8], header:PNGHeader) -> [RGBA<UInt16>]?
{
    guard header.color_type != .indexed
    else
    {
        fputs("Normalizing indexed PNGs is unsupported\n", stderr)
        return nil
    }

    let output:[RGBA<UInt16>]
    if header.bit_depth < 8 // channels is guaranteed to be 1
    {
        let quantum:UInt16 = UInt16.max / (UInt16.max >> (16 - UInt16(header.bit_depth)))
        output = stride(from: 0, to: raw_data.count << 3, by: header.bit_depth).map
        {
            let value:UInt16 = quantum * UInt16(bitval_extract(bit_index: $0, bit_depth: header.bit_depth, source: raw_data))
            return RGBA(value, value, value, UInt16.max)
        }
    }
    else
    {
        if header.bit_depth == 8
        {
            switch header.color_type
            {
            case .grayscale:
                output = raw_data.map
                {
                    let value:UInt16 = UInt16($0) << 8 | UInt16($0)
                    return RGBA(value, value, value, UInt16.max)
                }
            case .grayscale_a:
                output = stride(from: 0, to: raw_data.count, by: 2).map
                {
                    let value:UInt16 = UInt16(raw_data[$0    ]) << 8 | UInt16(raw_data[$0    ]),
                        alpha:UInt16 = UInt16(raw_data[$0 + 1]) << 8 | UInt16(raw_data[$0 + 1])
                    return RGBA(value, value, value, alpha)
                }
            case .rgb:
                output = stride(from: 0, to: raw_data.count, by: 3).map
                {
                    let r:UInt16 = UInt16(raw_data[$0    ]) << 8 | UInt16(raw_data[$0    ]),
                        g:UInt16 = UInt16(raw_data[$0 + 1]) << 8 | UInt16(raw_data[$0 + 1]),
                        b:UInt16 = UInt16(raw_data[$0 + 2]) << 8 | UInt16(raw_data[$0 + 2])
                    return RGBA(r, g, b, UInt16.max)
                }
            case .rgba:
                output = stride(from: 0, to: raw_data.count, by: 4).map
                {
                    let r:UInt16 = UInt16(raw_data[$0    ]) << 8 | UInt16(raw_data[$0    ]),
                        g:UInt16 = UInt16(raw_data[$0 + 1]) << 8 | UInt16(raw_data[$0 + 1]),
                        b:UInt16 = UInt16(raw_data[$0 + 2]) << 8 | UInt16(raw_data[$0 + 2]),
                        a:UInt16 = UInt16(raw_data[$0 + 3]) << 8 | UInt16(raw_data[$0 + 3])
                    return RGBA(r, g, b, a)
                }
            case .indexed:
                return nil // should never reach here
            }
        }
        else
        {
            switch header.color_type
            {
            case .grayscale:
                output = stride(from: 0, to: raw_data.count, by: 2).map
                {
                    let value:UInt16 = UInt16(raw_data[$0]) << 8 | UInt16(raw_data[$0 + 1])
                    return RGBA(value, value, value, UInt16.max)
                }
            case .grayscale_a:
                output = stride(from: 0, to: raw_data.count, by: 4).map
                {
                    let value:UInt16 = UInt16(raw_data[$0    ]) << 8 | UInt16(raw_data[$0 + 1]),
                        alpha:UInt16 = UInt16(raw_data[$0 + 2]) << 8 | UInt16(raw_data[$0 + 3])
                    return RGBA(value, value, value, alpha)
                }
            case .rgb:
                output = stride(from: 0, to: raw_data.count, by: 6).map
                {
                    let r:UInt16 = UInt16(raw_data[$0    ]) << 8 | UInt16(raw_data[$0 + 1]),
                        g:UInt16 = UInt16(raw_data[$0 + 2]) << 8 | UInt16(raw_data[$0 + 3]),
                        b:UInt16 = UInt16(raw_data[$0 + 4]) << 8 | UInt16(raw_data[$0 + 5])
                    return RGBA(r, g, b, UInt16.max)
                }
            case .rgba:
                output = stride(from: 0, to: raw_data.count, by: 8).map
                {
                    let r:UInt16 = UInt16(raw_data[$0    ]) << 8 | UInt16(raw_data[$0 + 1]),
                        g:UInt16 = UInt16(raw_data[$0 + 2]) << 8 | UInt16(raw_data[$0 + 3]),
                        b:UInt16 = UInt16(raw_data[$0 + 4]) << 8 | UInt16(raw_data[$0 + 5]),
                        a:UInt16 = UInt16(raw_data[$0 + 6]) << 8 | UInt16(raw_data[$0 + 7])
                    return RGBA(r, g, b, a)
                }
            case .indexed:
                return nil // should never reach here
            }
        }
    }

    return output
}

func bitval_extract(bit_index:Int, bit_depth:Int, source:[UInt8]) -> UInt8
{
    let byte_offset:Int  = bit_index >> 3
    let bit_offset:UInt8 = UInt8(bit_index & 7)
    var src_byte:UInt8   = source[byte_offset]
    /* mask out left */
    src_byte <<= bit_offset
    /* mask out right */
    src_byte >>= (8 - UInt8(bit_depth))
    return src_byte
}

func bitstamp(src_pos:Int, dest_pos:Int, bits:Int, source:[UInt8], dest:inout [UInt8])
{
    let src_byte_offset:Int  = src_pos >> 3
    let dest_byte_offset:Int = dest_pos >> 3
    let src_bit_offset:UInt8 = UInt8(src_pos & 7)
    var src_byte:UInt8       = source[src_byte_offset]
    /* mask out left */
    src_byte <<= src_bit_offset
    /* mask out right */
    src_byte >>= (8 - UInt8(bits))
    /* position it back where it should be */
    src_byte <<= (8 - src_bit_offset - UInt8(bits))
    /* write bits to destination */
    dest[dest_byte_offset] |= src_byte
}

func bytestamp(src_pos:Int, dest_pos:Int, bytes:Int, source:[UInt8], dest:inout [UInt8])
{
    dest[dest_pos ..< dest_pos + bytes] = source[src_pos ..< src_pos + bytes]
}

public
func deinterlace(raw_data:[UInt8], header:PNGHeader) throws -> [UInt8]
{
    guard raw_data.count == header.interlaced_data_size
    else
    {
        throw PNGWriteError.InterlaceDimensionError
    }

    var deinterlaced = [UInt8](repeating: 0, count: header.noninterlaced_data_size)
    var src_pixel_index = 0
    for (stride_h, stride_v) in header.sub_striders
    {
        for dest_pixel_base in stride_v.map({ $0 * header.width })
        {
            for dest_pixel_offset in stride_h
            {
                if header.bit_depth < 8
                {
                    /* channels is guaranteed to equal 1 */
                    var src_byte:UInt8       = raw_data[(src_pixel_index * header.bit_depth) >> 3],
                        src_bit_offset:UInt8 = UInt8((src_pixel_index * header.bit_depth) & 7)
                    /* mask out left */
                    src_byte <<= src_bit_offset
                    /* mask out right */
                    src_byte >>= (8 - UInt8(header.bit_depth))
                    /* position it back where it should be */
                    src_byte <<= (8 - src_bit_offset - UInt8(header.bit_depth))
                    /* write bits to destination */
                    let dest_byte_index:Int = ((dest_pixel_base + dest_pixel_offset) * header.bit_depth) >> 3
                    deinterlaced[dest_byte_index] |= src_byte
                }
                else
                {
                    let dest_byte_index:Int = (dest_pixel_base + dest_pixel_offset) * header.bpp,
                         src_byte_index:Int = src_pixel_index * header.bpp
                    deinterlaced[dest_byte_index ..< dest_byte_index + header.bpp] =
                        raw_data[src_byte_index  ..< src_byte_index  + header.bpp]
                }

                src_pixel_index += 1
            }
        }
    }

    return deinterlaced
}

public
func deinterlace(scanlines:[[UInt8]], header:PNGHeader) throws -> [[UInt8]]
{
    let (k, h):(Int, Int) = header.sub_array_bounds[7]
    var pixels:[[UInt8]] = [[UInt8]](repeating: [UInt8](repeating: 0, count: h), count: k)

    var l:Int = 0
    for (sub_array_bound, (u: u, v: v)) in zip(header.sub_array_bounds, header.sub_striders)
    {
        for (scanline, dest_pixel_row) in zip(scanlines[l..<(l + sub_array_bound.i)], v)
        {
            guard scanline.count == sub_array_bound.j
            else
            {
                throw PNGWriteError.InterlaceDimensionError
            }
            for (src_pixel_index, dest_pixel_index) in u.enumerated()
            {
                if header.bit_depth < 8
                {
                    /* channels is guaranteed to equal 1 */
                    bitstamp(src_pos: src_pixel_index * header.bit_depth,
                             dest_pos: dest_pixel_index * header.bit_depth,
                             bits: header.bit_depth,
                             source: scanline,
                             dest: &pixels[dest_pixel_row])
                }
                else
                {
                    bytestamp(src_pos: src_pixel_index * header.bpp,
                              dest_pos: dest_pixel_index * header.bpp,
                              bytes: header.bpp,
                              source: scanline,
                              dest: &pixels[dest_pixel_row])
                }
            }
        }
        l += sub_array_bound.i
    }

    return pixels
}

func absolute_unix_path(_ relative_path:String) -> String
{
    guard relative_path.characters.count > 1
    else
    {
        return relative_path
    }
    var expanded_path:String = relative_path
    if relative_path[relative_path.startIndex ..< relative_path.index(relative_path.startIndex, offsetBy: 2)] == "~/"
    {
        expanded_path = String(cString: getenv("HOME")) +
                        relative_path[relative_path.index(relative_path.startIndex, offsetBy: 1) ..< relative_path.endIndex]
    }
    return expanded_path
}

public
func decode_png(absolute_path:String) throws -> ([[UInt8]], PNGHeader)
{
    let png_decode = try PNGDecoder(path: absolute_path)
    var png_data:[[UInt8]] = []
    png_data.reserveCapacity(png_decode.header.height)
    while let scanline = try png_decode.next_scanline()
    {
        png_data.append(scanline)
    }

    if png_decode.header.interlace
    {
        png_data = try deinterlace(scanlines: png_data, header: png_decode.header)
    }

    return (png_data, png_decode.header)
}

public
func decode_png_contiguous(absolute_path:String) throws -> ([UInt8], PNGHeader)
{
    //let (png_data, header):([[UInt8]], PNGHeader) = try decode_png(absolute_path: absolute_path)
    //return (png_data.flatMap{ $0 }, header)

    guard let stream:FilePointer = fopen(absolute_path, "rb")
    else
    {
        throw PNGReadError.FileError(absolute_path)
    }
    defer { fclose(stream) }

    var decoder:Decoder                = try Decoder(stream: stream, look_for: [.IDAT]),
        scanline_iter:ScanlineIterator = ScanlineIterator(header: decoder.header)

    let zero_line:[UInt8]              = scanline_iter.make_zero_line()

    var reference_line:UnsafeBufferPointer<UInt8>?

    let buffer_size:Int = decoder.header.interlace ? decoder.header.interlaced_data_size : decoder.header.noninterlaced_data_size
    var buffer:[UInt8]  = [UInt8](repeating: 0, count: buffer_size)
    try buffer.withUnsafeMutableBufferPointer
    {
        (bp) in

        var offset:Int = 0
        while scanline_iter.update_scanline_size()
        {
            let dest = UnsafeMutableBufferPointer<UInt8>(start: bp.baseAddress! + offset, count: scanline_iter.bytes_per_scanline)
            //print("allocated: \(bp.baseAddress!  ) – \(bp.baseAddress! + bp.count) , offset = \(offset)/\(buffer_size)")
            //print("write to : \(dest.baseAddress!) – \(dest.baseAddress! + dest.count) (\(_count))")
            let filter:UInt8 = try decoder.decompress_scanline(stream: stream, dest: dest)
            if scanline_iter.first_scanline
            {
                zero_line.withUnsafeBufferPointer
                {
                    decoder.defilter_scanline(dest: dest, reference: $0, filter: filter)
                }
            }
            else
            {
                decoder.defilter_scanline(dest: dest, reference: reference_line!, filter: filter)
            }

            reference_line = UnsafeBufferPointer(start: dest.baseAddress, count: dest.count)
            offset += scanline_iter.bytes_per_scanline
        }
    }

    if decoder.header.interlace
    {
        buffer = try deinterlace(raw_data: buffer, header: decoder.header)
    }

    return (buffer, decoder.header)
}

public
func decode_png(relative_path:String) throws -> ([[UInt8]], PNGHeader)
{
    return try decode_png(absolute_path: absolute_unix_path(relative_path))
}

public
func decode_png_contiguous(relative_path:String) throws -> ([UInt8], PNGHeader)
{
    return try decode_png_contiguous(absolute_path: absolute_unix_path(relative_path))
}

func create_zstream() -> z_stream_s
{
    var stream = z_stream()
    stream.zalloc = nil
    stream.zfree = nil
    stream.opaque = nil
    stream.avail_in = 0
    stream.next_in = nil
    return stream
}

class ZIterator
{
    var stream:z_stream_s
    var input_ref:[UInt8] = [] // strongref the input buffer to prevent it from being deallocated prematurely

    init() throws
    {
        self.stream = create_zstream()
    }

    final
    func add_input(_ input:[UInt8])
    {
        self.input_ref       = input
        self.stream.avail_in = UInt32(input.count)
        self.stream.next_in  = UnsafeMutablePointer<UInt8>(mutating: self.input_ref)
    }

    final
    func set_output(dest:UnsafeMutableBufferPointer<UInt8>)
    {
        self.stream.avail_out = UInt32(dest.count)
        self.stream.next_out  = dest.baseAddress
    }
}

final
class ZInflator : ZIterator
// we cannot lower this to a struct because otherwise Swift clobbers Zlib’s internal state with its value semantics
{
    override
    init() throws
    {
        try super.init()
        guard inflateInit(&self.stream) == Z_OK
        else
        {
            throw PNGDecompressionError.StreamError
        }
    }

    deinit
    {
        inflateEnd(&self.stream)
    }

    func get_output_byte(sentinel:inout Bool) throws -> UInt8?
    {
        let _byte = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
        defer { _byte.deallocate(capacity: 1) }

        self.stream.avail_out = 1
        self.stream.next_out = _byte

        let inflate_status:Int32 = inflate(&self.stream, Z_NO_FLUSH)
        assert(inflate_status != Z_STREAM_ERROR) // this should never happen
        switch inflate_status
        {
            case Z_NEED_DICT:
                throw PNGDecompressionError.MissingDictionaryError
            case Z_DATA_ERROR:
                throw PNGDecompressionError.DataError
            case Z_MEM_ERROR:
                throw PNGDecompressionError.MemoryError
            default:
                break
        }

        sentinel = inflate_status == Z_STREAM_END

        guard self.stream.avail_out == 0
        else
        {
            return nil
        }

        return _byte.pointee
    }

    func get_output_bytes(sentinel:inout Bool) throws -> UInt32
    {
        let inflate_status:Int32 = inflate(&self.stream, Z_NO_FLUSH)
        assert(inflate_status != Z_STREAM_ERROR) // this should never happen
        switch inflate_status
        {
            case Z_NEED_DICT:
                throw PNGDecompressionError.MissingDictionaryError
            case Z_DATA_ERROR:
                throw PNGDecompressionError.DataError
            case Z_MEM_ERROR:
                throw PNGDecompressionError.MemoryError
            default:
                break
        }

        sentinel = inflate_status == Z_STREAM_END
        return self.stream.avail_out
    }
}

final
class ZDeflator : ZIterator
{
    override
    init() throws
    {
        try super.init()
        guard deflateInit(&self.stream, 9) == Z_OK
        else
        {
            throw PNGCompressionError.StreamError
        }
    }

    deinit
    {
        deflateEnd(&self.stream)
    }

    func get_output(sentinel:inout Bool, finish:Bool) throws -> UInt32
    {
        let deflate_status:Int32 = deflate(&stream, finish ? Z_FINISH : Z_NO_FLUSH)
        assert(deflate_status != Z_STREAM_ERROR) // this should never happen

        sentinel = deflate_status == Z_STREAM_END
        return self.stream.avail_out
    }
}

/* If you are wondering why these functions exist, it’s because Swift doesn’t know how to import C function macros yet. */
func inflateInit(_ strm:inout z_stream_s) -> Int32
{
    return inflateInit_(&strm, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
}

func deflateInit(_ strm:inout z_stream_s, _ level:Int32) -> Int32
{
    return deflateInit_(&strm, level, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
}
