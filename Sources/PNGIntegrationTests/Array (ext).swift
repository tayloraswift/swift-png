extension Array where Element == UInt8
{
    func load<T, U>(littleEndian:T.Type, as type:U.Type = U.self, at byte:Int) -> U
        where T:FixedWidthInteger, U:BinaryInteger
    {
        return self[byte ..< byte + MemoryLayout<T>.size].load(littleEndian: T.self, as: U.self)
    }
}
