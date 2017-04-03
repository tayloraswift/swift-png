import Zlib
import Glibc

typealias FilePointer = UnsafeMutablePointer<FILE>

public
enum PNGReadError:Error
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

public
enum PNGWriteError:Error
{
    case FileWriteError,
         DimemsionError
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

struct PNGConditions
{
    private(set)
    var seen = [Bool](repeating: false, count: PNGChunkType._cases.count)
    private(set)
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
        if chunk_type == .IEND && !self[.IDAT]
        // separated from the switch block because it doesn’t work right for some reason
        {
            throw PNGReadError.PrematureIENDError
        }

        switch chunk_type
        {
        // these chunks must occur before PLTE
        case .cHRM, .gAMA, .iCCP, .sBIT, .sRGB, .bKGD, .hIST, .tRNS:
            if self[.PLTE]
            {
                throw PNGReadError.ChunkOrderingError(String(describing: chunk_type))
            }
            fallthrough

        // these chunks must occur before IDAT
        case .PLTE, .cHRM, .gAMA, .iCCP, .sBIT, .sRGB, .bKGD, .hIST, .tRNS, .pHYs, .sPLT:
            if self[.IDAT]
            {
                throw PNGReadError.ChunkOrderingError(String(describing: chunk_type))
            }
            fallthrough


        // these chunks cannot duplicate
        case .IHDR, .PLTE, .IEND, .cHRM, .gAMA, .iCCP, .sBIT, .sRGB, .bKGD, .hIST, .tRNS, .pHYs, .sPLT, .tIME, .iTXt, .tEXt, .zTXT:
            if self[chunk_type]
            {
                throw PNGReadError.DuplicateChunkError(String(describing: chunk_type))
            }

        // IDAT blocks much be consecutive
        case .IDAT:
            if self.last_valid_chunk != .IDAT && self[.IDAT]
            {
                throw PNGReadError.ChunkOrderingError(String(describing: chunk_type))
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

    static
    let _cases:[PNGChunkType] = PNGChunkType._make_case_array()
    static private
    let _lookup:[Int: PNGChunkType] = PNGChunkType._make_case_lookup(PNGChunkType._cases)

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
            lookup[quad_byte_to_int([UInt8](String(describing: c).utf8))] = c
        }
        return lookup
    }

    static
    func from_buffer(_ buffer:[UInt8]) -> PNGChunkType?
    {
        return PNGChunkType._lookup[quad_byte_to_int(buffer)]
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
    guard let chunk_type = PNGChunkType.from_buffer(chunk_type_buffer)
    else
    {
        guard (chunk_type_buffer[0] & (1 << 5)) != 0
        else
        {
            throw PNGReadError.UnexpectedCriticalChunkError(PNGChunkType.string_rep(chunk_type_buffer))
        }
        guard (chunk_type_buffer[2] & (1 << 5)) == 0
        else
        {
            throw PNGReadError.PNGSyntaxError("Third byte of chunk type \(PNGChunkType.string_rep(chunk_type_buffer)) must have bit 5 set to 0.")
        }

        try skip_png_buffer(f, length)
        // ignore unrecognized chunk
        fputs("unrecognized: \(PNGChunkType.string_rep(chunk_type_buffer))", stderr)
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
            throw PNGReadError.DataCorruptionError(PNGChunkType.string_rep(chunk_type_buffer))
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
    let chunk_type_buffer:[UInt8] = [UInt8](String(describing: chunk_type).utf8)
    assert(chunk_type_buffer.count == 4)
    try write_png_buffer(f, buffer: chunk_type_buffer) // chunk type section
    try write_png_buffer(f, buffer: chunk_data) // chunk data section
    var calculated_crc:UInt = crc32(0, chunk_type_buffer, 4)
        calculated_crc      = crc32(calculated_crc, chunk_data, UInt32(chunk_data.count))
    try write_png_buffer(f, buffer: int_to_quad_byte(UInt32(calculated_crc))) // crc section // this Int() cast only works because crc is a 32 bit value padded to 64 bits
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

    public
    let sub_dimensions:[(width:Int, height:Int)]

    static
    let signature:[UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]

    let bpp:Int


    public
    init(width:Int, height:Int, bit_depth:Int, color_type:ColorType, interlace:Bool) throws
    {
        self.width = width
        self.height = height
        self.bit_depth = bit_depth
        self.color_type = color_type
        self.interlace = interlace

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
            throw PNGReadError.PNGSyntaxError("Color type '\(self.color_type)' cannot have a bit depth of \(self.bit_depth)")
        }

        self.bpp = max(1, (self.channels * self.bit_depth) >> 3)

        /* calculate size of interlaced subimages, if applicable */
        if self.interlace
        {
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
                                    (width: (self.width  + 0) >> 1, height: (self.height + 1) >> 1),
                                    (width: (self.width  + 0) >> 0, height: (self.height + 0) >> 1)]
        }
        else
        {
            self.sub_dimensions = [(width: self.width, height: self.height)]
        }
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
        let interlace_i = Int(data[12])
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

    func scanline_size(npixels:Int) -> Int
    {
        let scanline_bits_n = npixels * self.channels * self.bit_depth
        return (scanline_bits_n >> 3) + (scanline_bits_n & 7 == 0 ? 0 : 1)  // ceil(scanline_bits_n/8)
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
    var f:FilePointer

    private
    let z_iterator:ZDeflator
    private
    var defiltered0:[UInt8],
        chunk_data:[UInt8]

    private
    let chunk_size:Int
    private
    var chunk_empty:Int

    private
    let header:PNGImageHeader

    public
    init (path:String, header:PNGImageHeader, chunk_size:Int = 1 << 16) throws
    {
        if let f = fopen(path, "wb")
        {
            self.f = f
        }
        else
        {
            throw PNGReadError.FileError
        }

        self.chunk_size = chunk_size
        self.chunk_empty = self.chunk_size

        self.header = header
        self.z_iterator = try ZDeflator()
        self.defiltered0 = [UInt8](repeating: 0, count: header.scanline_size(npixels: header.sub_dimensions[0].width))
        self.chunk_data = [UInt8](repeating: 0, count: self.chunk_size)
    }

    deinit
    {
        fclose(self.f)
    }

    public
    func initialize() throws
    {
        try write_png_buffer(self.f, buffer: PNGImageHeader.signature)
        try png_write_chunk(f: self.f, chunk_data: self.header.write(), chunk_type: .IHDR)
    }

    public
    func add_scanline(_ defiltered1:[UInt8]) throws
    {
        guard defiltered1.count == defiltered0.count
        else
        {
            throw PNGWriteError.DimemsionError
        }

        var filter_data = [[UInt8]](repeating: [0] + defiltered1, count: 5)

        PNGEncoder.filter_sub    (&filter_data[1], bpp: self.header.bpp)
        PNGEncoder.filter_up     (&filter_data[2], defiltered0: self.defiltered0)
        PNGEncoder.filter_average(&filter_data[3], defiltered0: self.defiltered0, bpp: self.header.bpp)
        PNGEncoder.filter_paeth  (&filter_data[4], defiltered0: self.defiltered0, bpp: self.header.bpp)

        self.defiltered0 = defiltered1

        /* pick the most effective filter */
        let scores:[Int] = filter_data.map{ $0.reduce(0, {$0 + abs(Int(Int8(bitPattern: $1)))}) }
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

        repeat
        {
            let the_end:Bool
            (self.chunk_empty, the_end) = try self.z_iterator.get_output(&self.chunk_data, empty: self.chunk_empty)
            assert(!the_end) // the_end cannot come yet
        } while try self.attempt_emit_idat_chunk()
    }

    public
    func finish() throws
    {
        self.z_iterator.finish()
        var the_end:Bool
        repeat
        {
            (self.chunk_empty, the_end) = try self.z_iterator.get_output(&self.chunk_data, empty: self.chunk_empty)
        } while try self.attempt_emit_idat_chunk()
        assert(the_end) // the end must come now
        if self.chunk_empty != self.chunk_data.count // meaning, there is still data in the buffer
        {
            try png_write_chunk(f: self.f, chunk_data: [UInt8](self.chunk_data.dropLast(self.chunk_empty)), chunk_type: .IDAT)
        }
        try png_write_chunk(f: self.f, chunk_data: [], chunk_type: .IEND)
    }

    private
    func attempt_emit_idat_chunk() throws -> Bool
    {
        if self.chunk_empty == 0
        {
            /* emit chunk */
            try png_write_chunk(f: self.f, chunk_data: self.chunk_data, chunk_type: .IDAT)
            self.chunk_empty = self.chunk_size
            return true
        }
        else
        {
            return false
        }
    }

    /* these are literally exactly the same as the defilter functions except backwards */
    private static
    func filter_sub(_ filtered1:inout [UInt8], bpp:Int)
    {
        for i in ((1 + bpp)..<filtered1.count).reversed()
        {
            filtered1[i] = filtered1[i] &- filtered1[i - bpp]
        }
    }

    private static
    func filter_up(_ filtered1:inout [UInt8], defiltered0:[UInt8])
    {
        for i in 1..<filtered1.count // we do not need to reverse here
        {
            filtered1[i] = filtered1[i] &- defiltered0[i - 1]
        }
    }

    private static
    func filter_average(_ filtered1:inout [UInt8], defiltered0:[UInt8], bpp:Int)
    {
        for i in ((1 + bpp)..<filtered1.count).reversed()
        {
            filtered1[i] = filtered1[i] &- UInt8((UInt16(filtered1[i - bpp]) + UInt16(defiltered0[i - 1])) >> 1) // the second part will never overflow because of the right shift
        }
        for i in 1..<(1 + bpp) // we do not need to reverse here
        {
            filtered1[i] = filtered1[i] &- defiltered0[i - 1] >> 1
        }
    }

    private static
    func filter_paeth(_ filtered1:inout [UInt8], defiltered0:[UInt8], bpp:Int)
    {

        for i in ((1 + bpp)..<filtered1.count).reversed()
        {
            filtered1[i] = filtered1[i] &- paeth(filtered1[i - bpp], defiltered0[i - 1], defiltered0[i - 1 - bpp])
        }
        for i in 1..<(1 + bpp)
        {
            filtered1[i] = filtered1[i] &- paeth(0, defiltered0[i - 1], 0)
        }
    }
}

public final
class PNGDecoder
{
    private
    var f:UnsafeMutablePointer<FILE>

    private
    var conditions = PNGConditions()
    private
    var current_chunk_type:PNGChunkType = .__FIRST__

    private
    let z_iterator:ZInflator
    private
    var the_end:Bool = false
    private
    var defiltered0:[UInt8],
        scanline1:[UInt8]

    private
    var interlace_level:Int = 0,
        scanline_bytes:Int,
        scanline_rows_remaining:Int

    public
    let header:PNGImageHeader

    /*
    public private(set)
    var palatte:[(r: Int, g: Int, b: Int)]? = nil // not implemented yet — the number of channels is not fixed
    */

    public
    init(path:String, look_for:[PNGChunkType] = [.IDAT]) throws
    {
        if let f = fopen(path, "rb")
        {
            self.f = f
        }
        else
        {
            throw PNGReadError.FileError
        }

        /* check if it's, you know, actually a PNG */
        guard (try read_png_buffer(f, 8) == PNGImageHeader.signature) // compare with PNG signature
        else
        {
            throw PNGReadError.FiletypeError
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
            throw PNGReadError.MissingHeaderError
        }

        /* do the interlacing math */
        self.scanline_rows_remaining = self.header.sub_dimensions[0].height
        self.scanline_bytes          = self.header.scanline_size(npixels: self.header.sub_dimensions[0].width)

        self.z_iterator = try ZInflator()
        /* initialize the scanline buffers */
        self.defiltered0 = [UInt8](repeating: 0, count: self.scanline_bytes)
        self.scanline1 = [UInt8](repeating: 0, count: self.scanline_bytes + 1) // +1 is for the filter byte

        try self.read_png_info(look_for: look_for)
    }

    deinit
    {
        fclose(self.f)
    }

    private
    func read_png_info(look_for:[PNGChunkType]) throws // only ever call this function ONCE!
    {
        assert(self.current_chunk_type != .IDAT)
        var active_chunks:Set<PNGChunkType> = Set(look_for)
        active_chunks.insert(.IEND) // we must always be vigilant

        outer_loop: while true
        {
            if let (chunk_type, chunk_data) = try png_read_chunk(f: self.f, conditions: &self.conditions, one_of: active_chunks)
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

    private
    func read_scanline() throws
    {
        /* the subimage incrementor occurs *before* the rest of the function so that
           the last scanline of the subimage doesn’t get overwritten before it is emitted */
        if self.scanline_rows_remaining <= 0
        {
            self.interlace_level += 1
            let width:Int = self.header.sub_dimensions[self.interlace_level].width
            self.scanline_bytes          = self.header.scanline_size(npixels: width)
            self.scanline_rows_remaining = self.header.sub_dimensions[self.interlace_level].height

            self.defiltered0 = [UInt8](repeating: 0, count: self.scanline_bytes)
            self.scanline1 = [UInt8](repeating: 0, count: self.scanline_bytes + 1) // +1 is for the filter byte
        }

        var empty:Int = self.scanline1.count
        while true
        {
            (empty, self.the_end) = try self.z_iterator.get_output(&self.scanline1, empty: empty)
            /* if the output is full, break loop, else add more input */
            if empty == 0
            {
                break
            }
            guard !self.the_end
            else
            {
                throw PNGReadError.PrematureEOSError
            }
            /* read another IDAT chunk */
            let (chunk_type, chunk_data) = try png_read_chunk(f: self.f, conditions: &self.conditions, one_of: Set<PNGChunkType>([.IDAT]))!

            assert(chunk_type == .IDAT) // this should already be verified from the PNG conditions struct
            self.current_chunk_type = .IDAT
            self.z_iterator.add_input(chunk_data)
        }

        self.scanline_rows_remaining -= 1
    }

    public
    func next_scanline() throws -> [UInt8]?
    {
        guard self.current_chunk_type == .IDAT
        else
        {
            fputs("attempt to read scanlines without .IDAT flag set, please call `PNGDataIterator.init()` with `.IDAT` in the `look_for` field to read image pixels", stderr)
            return nil
        }
        guard !self.the_end
        else
        {
            return nil
        }
        try self.read_scanline()
        let filter = self.scanline1[0]
        var defiltered1 = Array(self.scanline1.dropFirst(1))
        switch filter
        {
        case 0:
            break
        case 1:
            PNGDecoder.defilter_sub(&defiltered1, bpp: self.header.bpp)
        case 2:
            PNGDecoder.defilter_up(&defiltered1, defiltered0: self.defiltered0)
        case 3:
            PNGDecoder.defilter_average(&defiltered1, defiltered0: self.defiltered0, bpp: self.header.bpp)
        case 4:
            PNGDecoder.defilter_paeth(&defiltered1, defiltered0: self.defiltered0, bpp: self.header.bpp)
        default:
            break // won’t happen
        }
        self.defiltered0 = defiltered1
        return defiltered1
    }

    private static
    func defilter_sub(_ defiltered1:inout [UInt8], bpp:Int)
    {
        for i in bpp..<defiltered1.count
        {
            defiltered1[i] = defiltered1[i] &+ defiltered1[i - bpp]
        }
    }

    private static
    func defilter_up(_ defiltered1:inout [UInt8], defiltered0:[UInt8])
    {
        for i in 0..<defiltered1.count
        {
            defiltered1[i] = defiltered1[i] &+ defiltered0[i]
        }
    }

    private static
    func defilter_average(_ defiltered1:inout [UInt8], defiltered0:[UInt8], bpp:Int)
    {
        for i in 0..<bpp
        {
            defiltered1[i] = defiltered1[i] &+ defiltered0[i] >> 1
        }
        for i in bpp..<defiltered1.count
        {
            defiltered1[i] = defiltered1[i] &+ UInt8((UInt16(defiltered1[i - bpp]) + UInt16(defiltered0[i])) >> 1) // the second part will never overflow because of the right shift
        }
    }

    private static
    func defilter_paeth(_ defiltered1:inout [UInt8], defiltered0:[UInt8], bpp:Int)
    {
        for i in 0..<bpp
        {
            defiltered1[i] = defiltered1[i] &+ paeth(0, defiltered0[i], 0)
        }
        for i in bpp..<defiltered1.count
        {
            defiltered1[i] = defiltered1[i] &+ paeth(defiltered1[i - bpp], defiltered0[i], defiltered0[i - bpp])
        }
    }
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

func add_input_to_zstream(_ stream:inout z_stream_s, input:[UInt8])
{
    stream.avail_in = UInt32(input.count)
    stream.next_in = UnsafeMutablePointer<UInt8>(mutating: input)
}

func allocate_output_for_zstream(_ stream:inout z_stream_s, output_buffer:inout [UInt8], empty:Int)
{
    stream.avail_out = UInt32(empty)
    stream.next_out = UnsafeMutablePointer<UInt8>(mutating: output_buffer).advanced(by: output_buffer.count - empty)
}

final
class ZInflator
{
    private
    var stream:z_stream_s

    private
    var input_ref:[UInt8] = [] // strongref the input buffer to prevent it from being deallocated prematurely

    init() throws
    {
        self.stream = create_zstream()
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

    func add_input(_ input:[UInt8])
    {
        self.input_ref = input
        add_input_to_zstream(&self.stream, input: input)
    }

    func get_output(_ output_buffer:inout [UInt8], empty:Int) throws -> (empty:Int, the_end:Bool)
    {
        var inflate_status:Int32 = Z_OK
        allocate_output_for_zstream(&self.stream, output_buffer: &output_buffer, empty: empty)
        inflate_status = inflate(&stream, Z_NO_FLUSH)
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
        return (Int(self.stream.avail_out), inflate_status == Z_STREAM_END)
    }
}

final
class ZDeflator
{
    private
    var stream:z_stream_s

    private
    var input_ref:[UInt8] = [] // strongref the input buffer to prevent it from being deallocated prematurely

    private
    var finished:Int32 = Z_NO_FLUSH

    init() throws
    {
        self.stream = create_zstream()
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

    func add_input(_ input:[UInt8])
    {
        self.input_ref = input
        add_input_to_zstream(&self.stream, input: input)
    }

    func finish()
    {
        self.finished = Z_FINISH
    }

    func get_output(_ output_buffer:inout [UInt8], empty:Int) throws -> (empty:Int, the_end:Bool)
    {
        var deflate_status:Int32 = Z_OK
        allocate_output_for_zstream(&self.stream, output_buffer: &output_buffer, empty: empty)
        deflate_status = deflate(&stream, self.finished)
        assert(deflate_status != Z_STREAM_ERROR) // this should never happen
        return (Int(self.stream.avail_out), deflate_status == Z_STREAM_END)
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
