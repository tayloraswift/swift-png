protocol _LZ77SymbolPattern
{
    associatedtype Symbol
    init(_ symbol:Symbol, length:Int)
}
extension LZ77.Symbol
{
    typealias Pattern = _LZ77SymbolPattern
}
