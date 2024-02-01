import CRC

extension Gzip.Format
{
    @frozen @usableFromInline
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
    @inlinable
    var checksum:UInt32 { self.crc32.checksum }

    @inlinable mutating
    func update(from buffer:UnsafePointer<UInt8>, count:Int)
    {
        self.crc32.update(with: UnsafeBufferPointer.init(start: buffer, count: count))
        self.bytes += UInt32.init(count)
    }
}
