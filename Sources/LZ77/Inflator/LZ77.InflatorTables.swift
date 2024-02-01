extension LZ77
{
    @frozen @usableFromInline
    struct InflatorTables
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
extension LZ77.InflatorTables
{
    init(literals:LZ77.HuffmanTree<UInt16>, distances:LZ77.HuffmanTree<UInt8>)
    {
        let start:Int   = 256    + MemoryLayout<Composite>.stride * 64
        let offset:Int  = start  + MemoryLayout<LZ77.RunLiteral>.stride * literals.size.z
        let size:Int    = offset + MemoryLayout<LZ77.Distance  >.stride * distances.size.z
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
            (base +  start).withMemoryRebound(to: LZ77.RunLiteral.self,
                capacity: literals.size.z)
            {
                literals.table(initializing: $0)
            }
            (base + offset).withMemoryRebound(to: LZ77.Distance.self,
                capacity: distances.size.z)
            {
                distances.table(initializing: $0)
            }
        }

        self.fence  = (runliteral: literals.size.n, distance: distances.size.n)
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

    subscript(codeword:UInt16, as _:LZ77.RunLiteral.Type) -> LZ77.RunLiteral
    {
        self.storage.withUnsafeMutablePointerToElements
        {
            let raw:UnsafeRawPointer = .init($0)
            // should get constant-folded
            let start:Int  = 256    + 64 * MemoryLayout<Composite>.stride
            let offset:Int = start &+ MemoryLayout<LZ77.RunLiteral>.stride &*
                self.index(codeword, fence: self.fence.runliteral)
            return raw.load(fromByteOffset: offset, as: LZ77.RunLiteral.self)
        }
    }
    subscript(codeword:UInt16, as _:LZ77.Distance.Type) -> LZ77.Distance
    {
        self.storage.withUnsafeMutablePointerToElements
        {
            let raw:UnsafeRawPointer = .init($0)
            let offset:Int = self.offset &+ MemoryLayout<LZ77.Distance>.stride &*
                self.index(codeword, fence: self.fence.distance)
            return raw.load(fromByteOffset: offset, as: LZ77.Distance.self)
        }
    }

    func composite(decade runliteral:LZ77.RunLiteral) -> (extra:Int, base:Int)
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
    func composite(decade distance:LZ77.Distance) -> (extra:Int, base:Int)
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
    let fixed:Self = .init(literals: .runliteral, distances: .distance)
}
