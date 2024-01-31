extension LZ77.InflatorTables
{
    @frozen @usableFromInline
    struct Meta
    {
        private
        var storage:ManagedBuffer<Void, UInt8>
    }
}
extension LZ77.InflatorTables.Meta
{
    private static
    var size:Int
    {
        256 + 256 * MemoryLayout<LZ77.Metaword>.stride
    }

    init()
    {
        self.storage = .create(minimumCapacity: Self.size){ _ in () }
        self.storage.withUnsafeMutablePointerToElements
        {
            $0.initialize(from: LZ77.Reversed.table, count: 256)
        }
    }

    mutating
    func exclude()
    {
        if !isKnownUniquelyReferenced(&self.storage)
        {
            #if WARN_COPY_ON_WRITE
            print("warning: managed buffer in type '\(String.init(reflecting: Self.self))' has multiple references; buffer is being copied to preserve value semantics")
            #endif

            self.storage = self.storage.withUnsafeMutablePointerToElements
            {
                (body:UnsafeMutablePointer<UInt8>) in

                let new:ManagedBuffer<Void, UInt8> =
                    .create(minimumCapacity: Self.size){ _ in () }
                new.withUnsafeMutablePointerToElements
                {
                    $0.initialize(from: body, count: Self.size)
                }
                return new
            }
        }
    }

    func replace(tree:LZ77.HuffmanTree<UInt8>)
    {
        assert(tree.size.z <= 256)
        self.storage.withUnsafeMutablePointerToElements
        {
            // write huffman tables
            ($0 + 256).withMemoryRebound(to: LZ77.Metaword.self, capacity: 256)
            {
                tree.table(initializing: $0)
            }
        }
    }

    subscript(codeword:UInt8) -> LZ77.Metaword
    {
        self.storage.withUnsafeMutablePointerToElements
        {
            let raw:UnsafeRawPointer    = .init($0)
            let index:Int               = .init($0[.init(codeword)])
            let offset:Int              = 256 &+
                MemoryLayout<LZ77.Metaword>.stride &* index
            return raw.load(fromByteOffset: offset, as: LZ77.Metaword.self)
        }
    }
}
