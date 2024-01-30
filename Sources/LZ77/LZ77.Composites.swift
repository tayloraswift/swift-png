extension LZ77
{
    enum Composites
    {
        // these are only used by the deflator in deflate.swift,, the inflator
        // reads these values from the Semistatic table, for memory locality
        static
        subscript(run decade:UInt8) -> (extra:UInt16, base:UInt16)
        {
            return Self.table[.init(decade)]
        }
        static
        subscript(distance decade:UInt8) -> (extra:UInt16, base:UInt16)
        {
            return Self.table[.init(32 | decade)]
        }

        static
        let table:[(extra:UInt16, base:UInt16)] =
        [
            // front-padding, which allows us to use a bitmask to
            // get the decade index
            (0,   0),

            // run decades
            (0,   3),
            (0,   4),
            (0,   5),
            (0,   6),
            (0,   7),

            (0,   8),
            (0,   9),
            (0,  10),
            (1,  11),
            (1,  13),

            (1,  15),
            (1,  17),
            (2,  19),
            (2,  23),
            (2,  27),

            (2,  31),
            (3,  35),
            (3,  43),
            (3,  51),
            (3,  59),

            (4,  67),
            (4,  83),
            (4,  99),
            (4, 115),
            (5, 131),

            (5, 163),
            (5, 195),
            (5, 227),
            (0, 258),

            // padding values, because out-of-bounds symbols occur
            // in fixed huffman trees, and may be erroneously decoded
            // if the decoder goes beyond the end-of-stream (which it is
            // temporarily allowed to do, for performance)
            (0,   0),
            (0,   0),

            // distance decades
            ( 0,     1),
            ( 0,     2),
            ( 0,     3),
            ( 0,     4),
            ( 1,     5),

            ( 1,     7),
            ( 2,     9),
            ( 2,    13),
            ( 3,    17),
            ( 3,    25),

            ( 4,    33),
            ( 4,    49),
            ( 5,    65),
            ( 5,    97),
            ( 6,   129),

            ( 6,   193),
            ( 7,   257),
            ( 7,   385),
            ( 8,   513),
            ( 8,   769),

            ( 9,  1025),
            ( 9,  1537),
            (10,  2049),
            (10,  3073),
            (11,  4097),

            (11,  6145),
            (12,  8193),
            (12, 12289),
            (13, 16385),
            (13, 24577),

            // padding values, because out-of-bounds symbols occur
            // in fixed huffman trees, and may be erroneously decoded
            // if the decoder goes beyond the end-of-stream (which it is
            // temporarily allowed to do, for performance)
            ( 0,     0),
            ( 0,     0),
        ]
    }
}
