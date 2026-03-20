extension LZ77 {
    enum BlockType {
        case dynamic
        case fixed
        case bytes(count: Int)
    }
}
