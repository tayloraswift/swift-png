extension LZ77.Deflator.Dicing
{
    enum Node
    {
        case interior(prefix:Int, suffix:Int)
        case leaf(terms:Range<Int>, dynamic:
        (
            codelengths:[UInt16],
            runliterals:Int,
            distances:Int,
            metaterms:[LZ77.Deflator.Term.Meta],
            tree:
            (
                runliteral:LZ77.HuffmanTree<UInt16>,
                distance:LZ77.HuffmanTree<UInt8>,
                meta:LZ77.HuffmanTree<UInt8>
            )
        )?)
    }
}
