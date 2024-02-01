import CRC

extension CRC32:LZ77.StreamIntegral
{
    @inlinable public
    init()
    {
        self.init(checksum: 0)
    }

    @inlinable public mutating
    func update(from buffer:UnsafePointer<UInt8>, count:Int)
    {
        self.update(with: UnsafeBufferPointer.init(start: buffer, count: count))
    }
}
