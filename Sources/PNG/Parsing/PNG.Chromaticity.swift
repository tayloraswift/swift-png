extension PNG
{
    /// A chromaticity descriptor.
    ///
    /// This type models the information stored in a ``Chunk/cHRM`` chunk.
    public
    struct Chromaticity
    {
        /// The white point of an image, expressed as a pair of fractions.
        public
        let w:(x:Percentmille, y:Percentmille)
        /// The chromaticity of the red component of an image,
        /// expressed as a pair of fractions.
        public
        let r:(x:Percentmille, y:Percentmille)
        /// The chromaticity of the green component of an image,
        /// expressed as a pair of fractions.
        public
        let g:(x:Percentmille, y:Percentmille)
        /// The chromaticity of the blue component of an image,
        /// expressed as a pair of fractions.
        public
        let b:(x:Percentmille, y:Percentmille)

        /// Creates a chromaticity descriptor with the given values.
        /// -   Parameter w:
        ///     The white point, expressed as a pair of fractions.
        /// -   Parameter r:
        ///     The red chromaticity, expressed as a pair of fractions.
        /// -   Parameter g:
        ///     The green chromaticity, expressed as a pair of fractions.
        /// -   Parameter b:
        ///     The blue chromaticity, expressed as a pair of fractions.
        public
        init(
            w:(x:Percentmille, y:Percentmille),
            r:(x:Percentmille, y:Percentmille),
            g:(x:Percentmille, y:Percentmille),
            b:(x:Percentmille, y:Percentmille))
        {
            self.w = w
            self.r = r
            self.g = g
            self.b = b
        }
    }
}
extension PNG.Chromaticity
{
    /// Creates a chromaticity descriptor by parsing the given chunk data.
    /// -   Parameter data:
    ///     The contents of a ``Chunk/cHRM`` chunk to parse.
    public
    init(parsing data:[UInt8]) throws
    {
        guard data.count == 32
        else
        {
            throw PNG.ParsingError.invalidChromaticityChunkLength(data.count)
        }

        self.w.x = .init(data.load(bigEndian: UInt32.self, as: Int.self, at:  0))
        self.w.y = .init(data.load(bigEndian: UInt32.self, as: Int.self, at:  4))
        self.r.x = .init(data.load(bigEndian: UInt32.self, as: Int.self, at:  8))
        self.r.y = .init(data.load(bigEndian: UInt32.self, as: Int.self, at: 12))
        self.g.x = .init(data.load(bigEndian: UInt32.self, as: Int.self, at: 16))
        self.g.y = .init(data.load(bigEndian: UInt32.self, as: Int.self, at: 20))
        self.b.x = .init(data.load(bigEndian: UInt32.self, as: Int.self, at: 24))
        self.b.y = .init(data.load(bigEndian: UInt32.self, as: Int.self, at: 28))
    }
    /// Encodes this chromaticity descriptor as the contents of a
    /// ``Chunk/cHRM`` chunk.
    public
    var serialized:[UInt8]
    {
        .init(unsafeUninitializedCapacity: 32)
        {
            $0.store(self.w.x.points, asBigEndian: UInt32.self, at:  0)
            $0.store(self.w.y.points, asBigEndian: UInt32.self, at:  4)

            $0.store(self.r.x.points, asBigEndian: UInt32.self, at:  8)
            $0.store(self.r.y.points, asBigEndian: UInt32.self, at: 12)

            $0.store(self.g.x.points, asBigEndian: UInt32.self, at: 16)
            $0.store(self.g.y.points, asBigEndian: UInt32.self, at: 20)

            $0.store(self.b.x.points, asBigEndian: UInt32.self, at: 24)
            $0.store(self.b.y.points, asBigEndian: UInt32.self, at: 28)
            $1 = $0.count
        }
    }
}
extension PNG.Chromaticity:CustomStringConvertible
{
    public
    var description:String
    {
        """
        PNG.\(Self.self) (\(PNG.Chunk.cHRM))
        {
            w           : \(self.w)
            r           : \(self.r)
            g           : \(self.g)
            b           : \(self.b)
        }
        """
    }
}
