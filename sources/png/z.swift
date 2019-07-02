import zlib

protocol LZ77Stream
{
    var stream:UnsafeMutablePointer<z_stream>
    {
        get
        set
    }

    var input:[UInt8]
    {
        get
        set
    }
}
extension LZ77Stream
{
    static
    func createStream(initializingWith initializer:(UnsafeMutablePointer<z_stream>) -> Int32)
        throws -> UnsafeMutablePointer<z_stream>
    {
        let stream:UnsafeMutablePointer<z_stream> = .allocate(capacity: 1)
            stream.initialize(to:  .init(next_in: nil,
                                        avail_in: 0,
                                        total_in: 0,
                                        next_out: nil,
                                       avail_out: 0,
                                       total_out: 0,
                                             msg: nil,
                                           state: nil,

                                          zalloc: nil,
                                           zfree: nil,
                                          opaque: nil,

                                       data_type: 0,
                                           adler: 0,
                                        reserved: 0))
        guard initializer(stream) == Z_OK
        else
        {
            stream.deinitialize(count: 1)
            stream.deallocate()

            throw PNG.LZ77.Error.initialization
        }

        return stream
    }

    func destroyStream(deinitializingWith deinitializer:(UnsafeMutablePointer<z_stream>) -> Int32)
    {
        guard deinitializer(self.stream) == Z_OK
        else
        {
            fatalError("failed to deinitialize `z_stream` structure")
        }

        self.stream.deinitialize(count: 1)
        self.stream.deallocate()
    }

    var unprocessedCount:Int
    {
        get
        {
            return .init(self.stream.pointee.avail_in)
        }
        set(value)
        {
            self.stream.pointee.avail_in = .init(value)
        }
    }

    mutating
    func push(_ input:[UInt8])
    {
        // assert(self.stream.pointee.avail_in == 0)
        self.input            = input
        self.unprocessedCount = input.count
    }

    private
    func check(status:Int32) throws -> Bool
    {
        switch status
        {
            case Z_STREAM_END:
                return false

            case Z_OK,
                 Z_BUF_ERROR:
                return true

            case Z_NEED_DICT:
                throw PNG.LZ77.Error.missingDictionary

            case Z_DATA_ERROR:
                throw PNG.LZ77.Error.data

            case Z_MEM_ERROR:
                throw PNG.LZ77.Error.memory

            case Z_STREAM_ERROR:
                fatalError("deflate(_:_:) was called on \(Self.self) stream after having been passed Z_FINISH without being passed Z_FINISH")

            default:
                fatalError("unreachable error \(status)")
        }
    }

    // returns true if the stream is not finished, false otherwise
    // Z_BUF_ERROR is okay here because outer logic should prevent that from
    // happening, and it has no adverse effects on later, valid, calls
    func pull(extending destination:inout [UInt8], capacity:Int,
        from body:(UnsafeMutablePointer<z_stream>) -> Int32) throws -> Bool
    {
        var status:Int32 = Z_OK
        let pulled:[UInt8] = .init(unsafeUninitializedCapacity: capacity - destination.count) 
        {
            (buffer:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in 
            
            self.stream.pointee.next_out  = buffer.baseAddress 
            self.stream.pointee.avail_out = .init(buffer.count)
            
            status = self.input.withUnsafeBufferPointer
            {
                let offset:Int              = self.input.count - self.unprocessedCount
                self.stream.pointee.next_in = $0.baseAddress.map{ .init(mutating: $0 + offset) }

                return body(self.stream)
            }
            
            count = buffer.count - .init(self.stream.pointee.avail_out)
        }
        
        defer 
        {
            destination.append(contentsOf: pulled)
        }
        return try self.check(status: status)
    }

    // used to test for Z_STREAM_END. THIS FUNCTION CLOBBERS THE LZ77 STREAM.
    // ONLY CALL IT IF YOU EXPECT THE RESULT TO BE `false`
    func test(_ body:(UnsafeMutablePointer<z_stream>) -> Int32) throws -> Bool
    {
        var _bait:UInt8  = .init()
        let status:Int32 = withUnsafeMutablePointer(to: &_bait)
        {

            self.stream.pointee.next_out  = $0
            self.stream.pointee.avail_out = 1
            return self.input.withUnsafeBufferPointer
            {
                let offset:Int              = self.input.count - self.unprocessedCount
                self.stream.pointee.next_in = $0.baseAddress.map{ .init(mutating: $0 + offset) }

                return body(self.stream)

            }
        }

        return try self.check(status: status)
    }
}

extension PNG
{
    /// A namespace for LZ77 utilities. Not for public use.
    public
    enum LZ77
    {
        /// Errors that can occur in the LZ77 compression or decompression process.
        public
        enum Error:Swift.Error
        {
            /// A zlib stream object failed to initialize properly.
            case initialization
            /// The `Z_NEED_DICT` error occured.
            case missingDictionary
            /// The `Z_DATA_ERROR` error occured.
            case data
            /// The `Z_MEM_ERROR` error occured.
            case memory
        }
        
        final
        class Inflator:LZ77Stream
        {
            var stream:UnsafeMutablePointer<z_stream>,
                input:[UInt8] = []

            init() throws
            {
                self.stream = try Inflator.createStream
                {
                    inflateInit_($0, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
                }
            }

            deinit
            {
                self.destroyStream(deinitializingWith: inflateEnd(_:))
            }

            func pull(extending destination:inout [UInt8], capacity:Int) throws -> Bool
            {
                return try self.pull(extending: &destination, capacity: capacity)
                {
                    inflate($0, Z_NO_FLUSH)
                }
            }

            func test() throws -> Bool
            {
                return try self.test
                {
                    inflate($0, Z_NO_FLUSH)
                }
            }
        }
        
        final
        class Deflator:LZ77Stream
        {
            var stream:UnsafeMutablePointer<z_stream>,
                input:[UInt8] = []

            init(level:Int) throws
            {
                precondition(0 ..< 10 ~= level)
                self.stream = try Deflator.createStream
                {
                    deflateInit_($0, Int32(level), ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
                }
            }

            deinit
            {
                self.destroyStream(deinitializingWith: deflateEnd(_:))
            }

            // we don’t care about Z_STREAM_END for deflators
            @discardableResult
            func pull(extending destination:inout [UInt8], capacity:Int) throws -> Bool
            {
                return try self.pull(extending: &destination, capacity: capacity)
                {
                    deflate($0, Z_NO_FLUSH)
                }
            }

            func finish(extending destination:inout [UInt8], capacity:Int) throws -> Bool
            {
                return try self.pull(extending: &destination, capacity: capacity)
                {
                    deflate($0, Z_FINISH)
                }
            }
        }
    }
}
