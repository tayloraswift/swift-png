extension LZ77.Inflator
{
    struct Semistatic
    {
        private
        typealias Composite = (extra:UInt16, base:UInt16)

        private
        let storage:ManagedBuffer<Void, UInt8>,
            fence:(runliteral:Int, distance:Int),
            offset:Int
            //runliteral:(fence:Int, fold:Int),
            //distance:(offset:Int, fence:Int, fold:Int)
        //               stack
        //    0 ┌───────────────────────┐ : Buffer pointer
        //      ├───────────────────────┤ : Run-literal fence
        //      ├───────────────────────┤ : Distance fence
        //      ├───────────────────────┤ : Distance table offset
        //   32 └───────────────────────┘
        //                heap
        //    0 ┌───────────────────────┐
        //      │                       │
        //      │  byte reversal table  │ : 256 * UInt8
        //      │                       │
        //  256 ├───────────────────────┤
        //      │   Run decade table    │ : 32 * (UInt16, UInt16)
        //  384 ├───────────────────────┤
        //      │ Distance decade table │ : 32 * (UInt16, UInt16)
        //  512 ├───────────────────────┤
        //      │                       │
        //      │                       │
        //      │                       │
        //      │                       │
        //      │                       │
        //      │                       │
        //      │   Run-literal table   │
        //      │        (1-8 KB)       │
        //      │                       │
        //      │                       │
        //      │                       │
        //      │                       │
        //      │                       │
        //      │                       │
        //      │                       │
        //      ├───────────────────────┤
        //      │                       │
        //      │                       │
        //      │                       │
        //      │                       │
        //      │                       │
        //      │                       │
        //      │     Distance table    │
        //      │        (1-4 KB)       │
        //      │                       │
        //      │                       │
        //      │                       │
        //      │                       │
        //      │                       │
        //      │                       │
        //      │                       │
        //      └───────────────────────┘
    }
}
extension LZ77.Inflator.Semistatic
{
    init(runliteral:LZ77.Huffman<UInt16>, distance:LZ77.Huffman<UInt8>)
    {
        let start:Int   = 256    + MemoryLayout<Composite>.stride * 64
        let offset:Int  = start  + MemoryLayout<LZ77.Symbol.RunLiteral>.stride * runliteral.size.z
        let size:Int    = offset + MemoryLayout<LZ77.Symbol.Distance  >.stride *   distance.size.z
        self.storage = .create(minimumCapacity: size){ _ in () }
        self.storage.withUnsafeMutablePointerToElements
        {
            (base:UnsafeMutablePointer<UInt8>) in

            // write byte reversal table
            (base         ).initialize(from: LZ77.Reversed.table, count: 256)
            // write decade tables
            (base +    256).withMemoryRebound(to: Composite.self, capacity: 64)
            {
                $0.initialize(from: LZ77.Composites.table, count: 64)
            }
            // write huffman tables
            (base +  start).withMemoryRebound(to: LZ77.Symbol.RunLiteral.self,
                capacity: runliteral.size.z)
            {
                runliteral.table(initializing: $0)
            }
            (base + offset).withMemoryRebound(to: LZ77.Symbol.Distance.self,
                capacity: distance.size.z)
            {
                distance.table(initializing: $0)
            }
        }

        self.fence  = (runliteral: runliteral.size.n, distance: distance.size.n)
        self.offset = offset
    }

    // bits in lower half of the uint16
    private
    func reverse(_ byte:UInt16) -> Int
    {
        // fastest bit twiddle in the west,, now that i measured it
        // now i know why everyone at apple asks this same coding interview question
        self.storage.withUnsafeMutablePointerToElements
        {
            .init($0[.init(byte)])
        }
    }
    private
    func index(_ codeword:UInt16, fence:Int) -> Int
    {
        let first:Int = self.reverse(codeword & 0x00ff)
        return first <  fence ?
               first :
            (( first &- fence &+ 2 ) << 8 | self.reverse(codeword >> 8)) >> 1
    }

    subscript(codeword:UInt16, as _:LZ77.Symbol.RunLiteral.Type) -> LZ77.Symbol.RunLiteral
    {
        self.storage.withUnsafeMutablePointerToElements
        {
            let raw:UnsafeRawPointer = .init($0)
            // should get constant-folded
            let start:Int  = 256    + 64 * MemoryLayout<Composite>.stride
            let offset:Int = start &+ MemoryLayout<LZ77.Symbol.RunLiteral>.stride &*
                self.index(codeword, fence: self.fence.runliteral)
            return raw.load(fromByteOffset: offset, as: LZ77.Symbol.RunLiteral.self)
        }
    }
    subscript(codeword:UInt16, as _:LZ77.Symbol.Distance.Type) -> LZ77.Symbol.Distance
    {
        self.storage.withUnsafeMutablePointerToElements
        {
            let raw:UnsafeRawPointer = .init($0)
            let offset:Int = self.offset &+ MemoryLayout<LZ77.Symbol.Distance>.stride &*
                self.index(codeword, fence: self.fence.distance)
            return raw.load(fromByteOffset: offset, as: LZ77.Symbol.Distance.self)
        }
    }

    func composite(decade runliteral:LZ77.Symbol.RunLiteral) -> (extra:Int, base:Int)
    {
        self.storage.withUnsafeMutablePointerToElements
        {
            let raw:UnsafeRawPointer = .init($0)
            let offset:Int          = 256 &+
                MemoryLayout<Composite>.stride &* runliteral.decade
            let composite:Composite = raw.load(fromByteOffset: offset, as: Composite.self)
            return (extra: .init(composite.extra), base: .init(composite.base))
        }
    }
    func composite(decade distance:LZ77.Symbol.Distance) -> (extra:Int, base:Int)
    {
        self.storage.withUnsafeMutablePointerToElements
        {
            let raw:UnsafeRawPointer = .init($0)
            // should get constant-folded
            let offset:Int          = (256 + 32 * MemoryLayout<Composite>.stride) &+
                MemoryLayout<Composite>.stride &* distance.decade
            let composite:Composite = raw.load(fromByteOffset: offset, as: Composite.self)
            return (extra: .init(composite.extra), base: .init(composite.base))
        }
    }

    static
    let fixed:Self = .init(
        runliteral: LZ77.FixedHuffman.runliteral,
        distance:   LZ77.FixedHuffman.distance)
}
extension LZ77.Inflator.Semistatic
{
    struct Meta
    {
        private
        var storage:ManagedBuffer<Void, UInt8>
    }
}
extension LZ77.Inflator.Semistatic.Meta
{
    private static
    var size:Int
    {
        256 + 256 * MemoryLayout<LZ77.Symbol.Meta>.stride
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

    func replace(tree:LZ77.Huffman<UInt8>)
    {
        assert(tree.size.z <= 256)
        self.storage.withUnsafeMutablePointerToElements
        {
            // write huffman tables
            ($0 + 256).withMemoryRebound(to: LZ77.Symbol.Meta.self, capacity: 256)
            {
                tree.table(initializing: $0)
            }
        }
    }

    subscript(codeword:UInt8) -> LZ77.Symbol.Meta
    {
        self.storage.withUnsafeMutablePointerToElements
        {
            let raw:UnsafeRawPointer    = .init($0)
            let index:Int               = .init($0[.init(codeword)])
            let offset:Int              = 256 &+
                MemoryLayout<LZ77.Symbol.Meta>.stride &* index
            return raw.load(fromByteOffset: offset, as: LZ77.Symbol.Meta.self)
        }
    }
}
