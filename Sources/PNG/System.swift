//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/. 

#if os(macOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#elseif os(Windows)
    #warning("Windows in not oficially supported and is untested platform (please open an issue at https://github.com/kelvin13/swift-png/issues)")
    import ucrt
#else
    #warning("unsupported or untested platform (please open an issue at https://github.com/kelvin13/swift-png/issues)")
#endif

#if os(macOS) || os(Linux) || os(Windows)

/// enum System 
///     A namespace for platform-dependent functionality.
/// 
///     These APIs are only available on MacOS and Linux. The rest of the 
///     framework is pure Swift and supports all Swift platforms.
/// #  [File IO](system-file-io)
/// #  [See also](top-level-namespaces)
/// ## (2:top-level-namespaces)
public 
enum System 
{
    /// enum System.File 
    ///     A namespace for file IO functionality.
    /// ## (system-file-io)
    public
    enum File
    {
        typealias Descriptor = UnsafeMutablePointer<FILE>
        
        /// struct System.File.Source
        /// :   PNG.Bytestream.Source 
        ///     A type for reading data from files on disk.
        /// ## (system-file-io)
        /// ## (system-file-source)
        public
        struct Source
        {
            private
            let descriptor:Descriptor
        }
        
        /// struct System.File.Destination
        /// :   PNG.Bytestream.Destination
        ///     A type for writing data to files on disk.
        /// ## (system-file-io)
        /// ## (system-file-destination)
        public 
        struct Destination 
        {
            private 
            let descriptor:Descriptor
        }
    }
}
extension System.File.Source
{
    /// static func System.File.Source.open<R>(path:_:)
    /// rethrows 
    ///     Calls a closure with an interface for reading from the specified file.
    /// 
    ///     This method automatically closes the file when its closure argument returns.
    /// - path  : Swift.String 
    ///     The path to the file to open.
    /// - body  : (inout Self) throws -> R
    ///     A closure with a [`Source`] parameter from which data in
    ///     the specified file can be read. This interface is only valid
    ///     for the duration of the method’s execution. The closure is
    ///     only executed if the specified file could be successfully
    ///     opened, otherwise this method will return `nil`. If `body` has a 
    ///     return value and the specified file could be opened, this method 
    ///     returns the return value of the closure.
    /// - ->    : R?
    ///     The return value of the closure argument, or `nil` if the specified 
    ///     file could not be opened.
    public static
    func open<R>(path:String, _ body:(inout Self) throws -> R)
        rethrows -> R?
    {
        guard let descriptor:System.File.Descriptor = fopen(path, "rb")
        else
        {
            return nil
        }

        var file:Self = .init(descriptor: descriptor)
        defer
        {
            fclose(file.descriptor)
        }

        return try body(&file)
    }

    /// func System.File.Source.read(count:)
    /// ?:  PNG.Bytestream.Source 
    ///     Reads the specified number of bytes from this file interface.
    /// 
    ///     This method only returns an array if the exact number of bytes
    ///     specified could be read. This method advances the file pointer.
    /// - capacity  : Swift.Int 
    ///     The number of bytes to read.
    /// - ->        : [Swift.UInt8]?
    ///     An array containing the read data, or `nil` if the specified
    ///     number of bytes could not be read.
    public
    func read(count capacity:Int) -> [UInt8]?
    {
        let buffer:[UInt8] = .init(unsafeUninitializedCapacity: capacity)
        {
            (buffer:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in

            count = fread(buffer.baseAddress, MemoryLayout<UInt8>.stride,
                capacity, self.descriptor)
        }

        guard buffer.count == capacity
        else
        {
            return nil
        }

        return buffer
    }
    /// var System.File.Source.count : Swift.Int? { get }
    ///     The size of the file, in bytes, or `nil` if the file is not a regular 
    ///     file or a link to a file.
    /// 
    ///     This property queries the file size using `stat`.
    public 
    var count:Int? 
    {
        let descriptor:Int32 = fileno(self.descriptor)
        guard descriptor != -1 
        else 
        {
            return nil 
        }
        
        guard let status:stat = 
        ({
            var status:stat = .init()
            guard fstat(descriptor, &status) == 0 
            else 
            {
                return nil 
            }
            return status 
        }())
        else 
        {
            return nil 
        }
        
        #if os(Windows)
        switch Int32.init(status.st_mode) & S_IFMT 
        {
        case S_IFREG:
            break 
        default:
            return nil 
        }
        #else
        switch status.st_mode & S_IFMT 
        {
        case S_IFREG, S_IFLNK:
            break 
        default:
            return nil 
        }
        #endif
        
        return Int.init(status.st_size)
    } 
}
extension System.File.Destination
{
    /// static func System.File.Destination.open<R>(path:_:)
    /// rethrows 
    ///     Calls a closure with an interface for writing to the specified file.
    /// 
    ///     This method automatically closes the file when its closure argument returns.
    /// - path  : Swift.String 
    ///     The path to the file to open.
    /// - body  : (inout Self) throws -> R
    ///     A closure with a [`Destination`] parameter representing
    ///     the specified file to which data can be written to. This
    ///     interface is only valid for the duration of the method’s
    ///     execution. The closure is only executed if the specified file could 
    ///     be successfully opened, otherwise this method will return `nil`.
    ///     If `body` has a return value and the specified file could be opened, 
    ///     this method returns the return value of the closure.
    /// - ->    : R? 
    ///     The return value of the closure argument, or `nil` if the specified 
    ///     file could not be opened.
    public static
    func open<R>(path:String, _ body:(inout Self) throws -> R)
        rethrows -> R?
    {
        guard let descriptor:System.File.Descriptor = fopen(path, "wb")
        else
        {
            return nil
        }

        var file:Self = .init(descriptor: descriptor)
        defer
        {
            fclose(file.descriptor)
        }

        return try body(&file)
    }
    
    /// func System.File.Destination.write(_:)
    /// ?:  PNG.Bytestream.Destination
    ///     Write the bytes in the given array to this file interface.
    /// 
    ///     This method only returns `()` if the entire array argument could
    ///     be written. This method advances the file pointer.
    /// - buffer    : [Swift.UInt8] 
    ///     The data to write.
    /// - ->        : Swift.Void? 
    ///     A [`Swift.Void`] tuple if the entire array argument could be written,
    ///     or `nil` otherwise.
    public
    func write(_ buffer:[UInt8]) -> Void?
    {
        let count:Int = buffer.withUnsafeBufferPointer
        {
            fwrite($0.baseAddress, MemoryLayout<UInt8>.stride,
                $0.count, self.descriptor)
        }

        guard count == buffer.count
        else
        {
            return nil
        }

        return ()
    }
}

// declare conformance (as a formality)
extension System.File.Source:PNG.Bytestream.Source 
{
}
extension System.File.Destination:PNG.Bytestream.Destination 
{
}

extension PNG.Data.Rectangular 
{
    /// static func PNG.Data.Rectangular.decompress(path:)
    /// throws 
    ///     Decompresses and decodes a PNG from a file at the given file path. 
    /// 
    ///     This interface is only available on MacOS and Linux. The 
    ///     [`decompress(stream:)`] function provides a platform-independent 
    ///     decoding interface.
    /// - path : Swift.String  
    ///     A path to a PNG file.
    /// - -> : Self? 
    ///     The decoded image, or `nil` if the file at the given `path` could 
    ///     not be opened.
    /// # [See also](encoding-and-decoding)
    /// ## (1:encoding-and-decoding)
    /// ## (1:decoding)
    public static 
    func decompress(path:String) throws -> Self?
    {
        try System.File.Source.open(path: path)
        {
            try .decompress(stream: &$0)
        }
    }
    /// func PNG.Data.Rectangular.compress(path:level:hint:)
    /// throws 
    ///     Encodes and compresses a PNG to a file at the given file path. 
    ///
    ///     Compression `level` `9` is roughly equivalent to *libpng*’s maximum 
    ///     compression setting in terms of compression ratio and encoding speed. 
    ///     The higher levels (`10` through `13`) are very computationally expensive, 
    ///     so they should only be used when optimizing for file size. 
    /// 
    ///     Experimental comparisons between *Swift PNG* and *libpng*’s 
    ///     compression settings can be found on 
    ///     [this page](https://github.com/kelvin13/swift-png/blob/master/benchmarks).
    /// 
    ///     This interface is only available on MacOS and Linux. The 
    ///     [`compress(stream:level:hint:)`] function provides a platform-independent 
    ///     encoding interface.
    /// - path : Swift.String
    ///     A path to save the PNG file at.
    /// - level : Swift.Int 
    ///     The compression level to use. It should be in the range `0 ... 13`, 
    ///     where `13` is the most aggressive setting. The default value is `9`. 
    /// 
    ///     Setting this parameter to a value less than `0` is the same as 
    ///     setting it to `0`. Likewise, setting it to a value greater than `13` 
    ///     is the same as setting it to `13`.
    /// - hint : Swift.Int 
    ///     A size hint for the emitted [`(Chunk).IDAT`] chunks. It should be in 
    ///     the range `1 ... 2147483647`. Reasonable settings range from around 
    ///     1\ K to 64\ K. The default value is `32768` (2^15^). 
    /// 
    ///     Setting this parameter to a value less than `1` is the same as setting 
    ///     it to `1`. Likewise, setting it to a value greater than `2147483647` 
    ///     (2^31^\ –\ 1) is the same as setting it to `2147483647`.
    /// - -> : Swift.Void?
    ///     A [`Swift.Void`] tuple if the destination file could be opened
    ///     successfully, or `nil` otherwise.
    /// # [See also](encoding-and-decoding)
    /// ## (3:encoding-and-decoding)
    /// ## (1:encoding)
    public  
    func compress(path:String, level:Int = 9, hint:Int = 1 << 15) throws -> Void?
    {
        try System.File.Destination.open(path: path)
        {
            try self.compress(stream: &$0, level: level, hint: hint)
        }
    }
}
#endif 
