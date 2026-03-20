extension LZ77 {
    @frozen @usableFromInline enum InflatorState {
        case initial
        case block(LZ77.BlockState)
        case checksum
        case terminal
    }
}
