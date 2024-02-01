import CRC

extension Gzip.Format
{
    @frozen public
    struct Integral
    {
        @usableFromInline
        var crc32:CRC32
        @usableFromInline
        var bytes:UInt32

        @inlinable public
        init()
        {
            self.crc32 = .init()
            self.bytes = 0
        }
    }
}
extension Gzip.Format.Integral:LZ77.StreamIntegral
{
    @inlinable public
    var checksum:UInt32 { self.crc32.checksum }

    @inlinable public mutating
    func update(from buffer:UnsafePointer<UInt8>, count:Int)
    {
        self.crc32.update(with: UnsafeBufferPointer.init(start: buffer, count: count))
        self.bytes += UInt32.init(count)
    }
}
