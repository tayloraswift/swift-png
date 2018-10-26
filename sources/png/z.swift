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
    
    mutating 
    func push(_ input:[UInt8]) 
    {
        // assert(self.stream.pointee.avail_in == 0)
        self.input                   = input
        self.stream.pointee.avail_in = UInt32(input.count)
    }
    
    @discardableResult
    func pull(extending destination:inout [UInt8], capacity:Int, 
        from body:(UnsafeMutablePointer<z_stream>) -> Int32) throws -> Int
    {
        return try destination.withUnsafeMutableBufferPointerToStorage(capacity: capacity)
        {
            (buffer:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in
            
            self.stream.pointee.next_out  = buffer.baseAddress.map{ $0 + count }
            self.stream.pointee.avail_out = UInt32(capacity - count)
            
            let status:Int32 = self.input.withUnsafeBufferPointer 
            {
                let offset:Int = self.input.count - Int(self.stream.pointee.avail_in)
                self.stream.pointee.next_in = $0.baseAddress.map{ .init(mutating: $0 + offset) }
                
                return body(self.stream)
            }
            
            count = capacity - Int(self.stream.pointee.avail_out)
            
            switch status 
            {
                case Z_STREAM_END, 
                     Z_OK:
                    break 
                
                case Z_BUF_ERROR:
                    break
                
                case Z_NEED_DICT:
                    throw PNG.LZ77.Error.missingDictionary
                case Z_DATA_ERROR:
                    throw PNG.LZ77.Error.data
                case Z_MEM_ERROR:
                    throw PNG.LZ77.Error.memory
                    
                case Z_STREAM_ERROR:
                    fallthrough
                default:
                    fatalError("unreachable error \(status)")
            }
            
            return Int(self.stream.pointee.avail_in)
        }
    }
}

extension PNG 
{
    public 
    enum LZ77 
    {
        public  
        enum Error:Swift.Error 
        {
            case initialization, missingDictionary, data, memory
        }
        
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
            
            func pull(extending destination:inout [UInt8], capacity:Int) 
                throws -> Int
            {
                return try self.pull(extending: &destination, capacity: capacity)
                {
                    inflate($0, Z_NO_FLUSH)
                }
            }
        }
        
        class Deflator:LZ77Stream 
        {
            var stream:UnsafeMutablePointer<z_stream>, 
                input:[UInt8] = []
            
            init(level:Int) throws
            {
                assert(0 ..< 10 ~= level)
                self.stream = try Deflator.createStream 
                {
                    deflateInit_($0, Int32(level), ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
                }
            }
            
            deinit
            {
                self.destroyStream(deinitializingWith: deflateEnd(_:))
            }
            
            func pull(extending destination:inout [UInt8], capacity:Int) 
                throws -> Int
            {
                return try self.pull(extending: &destination, capacity: capacity)
                {
                    deflate($0, Z_NO_FLUSH)
                }
            }
            func finish(extending destination:inout [UInt8], capacity:Int) throws -> Bool
            {
                var continued:Bool = true 
                try self.pull(extending: &destination, capacity: capacity)
                {
                    let status:Int32 = deflate($0, Z_FINISH)
                    if status == Z_STREAM_END 
                    {
                        continued = false 
                    }
                    return status 
                }
                
                return continued
            }
        }
    }
}
