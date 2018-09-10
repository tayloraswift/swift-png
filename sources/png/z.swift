import zlib

extension PNG 
{
    enum DecompressionError:Error 
    {
        case initialization, missingDictionary, data, memory
    }
}

struct ZDecompressor 
{
    class Stream 
    {
        var stream:z_stream = .init()
        
        init?() 
        {
            let status:Int32 = withUnsafeMutablePointer(to: &self.stream) 
            {
                $0.pointee  = .init(next_in: nil, 
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
                                    reserved: 0)
                
                return inflateInit_($0, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
            } 
            
            guard status == Z_OK 
            else  
            {
                return nil 
            }
        }
        
        deinit
        {
            withUnsafeMutablePointer(to: &self.stream) 
            {
                inflateEnd($0)
                return 
            }
        }
    }
    
    private 
    var stream:Stream, 
        input:[UInt8] = []
    
    init() throws 
    {
        guard let stream:Stream = Stream.init() 
        else 
        {
            throw PNG.DecompressionError.initialization
        }
        
        self.stream = stream
    }
    
    mutating 
    func push(_ input:[UInt8]) 
    {
        self.input           = input
        withUnsafeMutablePointer(to: &self.stream.stream) 
        {
            $0.pointee.avail_in = UInt32(input.count)
        }
    }
    
    mutating 
    func pull(extending destination:inout [UInt8], capacity:Int) throws
    {
        try destination.withUnsafeMutableBufferPointerToStorage(capacity: capacity)
        {
            (buffer:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in
            
            try withUnsafeMutablePointer(to: &self.stream.stream) 
            {
                (storage:UnsafeMutablePointer<z_stream>) in 
                
                storage.pointee.next_out  = buffer.baseAddress.map{ $0 + count }
                storage.pointee.avail_out = UInt32(capacity - count)
                
                let status:Int32 = self.input.withUnsafeBufferPointer 
                {
                    let offset:Int = self.input.count - Int(storage.pointee.avail_in)
                    storage.pointee.next_in = $0.baseAddress.map{ .init(mutating: $0 + offset) }
                    
                    return inflate(storage, Z_NO_FLUSH)
                }
                
                count = capacity - Int(storage.pointee.avail_out)
                
                switch status 
                {
                    case Z_STREAM_END, 
                         Z_OK:
                        break 
                    
                    case Z_BUF_ERROR:
                        break
                    
                    case Z_NEED_DICT:
                        throw PNG.DecompressionError.missingDictionary
                    case Z_DATA_ERROR:
                        throw PNG.DecompressionError.data
                    case Z_MEM_ERROR:
                        throw PNG.DecompressionError.memory
                        
                    case Z_STREAM_ERROR:
                        fallthrough
                    default:
                        fatalError("unreachable error \(status)")
                }
            }
        }
    }
}
