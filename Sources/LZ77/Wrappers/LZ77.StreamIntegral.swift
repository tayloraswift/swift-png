extension LZ77
{
    @usableFromInline
    typealias StreamIntegral = _LZ77StreamIntegral
}
@usableFromInline
protocol _LZ77StreamIntegral
{
    init()

    mutating
    func update(from buffer:UnsafePointer<UInt8>, count:Int)

    var checksum:UInt32 { get }
}
