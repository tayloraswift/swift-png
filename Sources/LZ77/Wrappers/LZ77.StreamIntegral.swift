extension LZ77
{
    @usableFromInline
    protocol StreamIntegral
    {
        init()

        mutating
        func update(from buffer:UnsafePointer<UInt8>, count:Int)

        var checksum:UInt32 { get }
    }
}
