extension UnsafeMutableBufferPointer where Element == UInt8
{
    func store<U, T>(_ value:U, asBigEndian type:T.Type, at byte:Int = 0)
        where U:BinaryInteger, T:FixedWidthInteger
    {
        let cast:T = .init(truncatingIfNeeded: value)
        withUnsafeBytes(of: cast.bigEndian)
        {
            guard   let source:UnsafeRawPointer             = $0.baseAddress,
                    let destination:UnsafeMutableRawPointer =
                self.baseAddress.map(UnsafeMutableRawPointer.init(_:))
            else
            {
                return
            }

            (destination + byte).copyMemory(from: source, byteCount: MemoryLayout<T>.size)
        }
    }
}
