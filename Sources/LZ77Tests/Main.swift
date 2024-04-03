import Testing

@main
enum Main:TestMain
{
    #if DEBUG
    static
    let all:[any TestBattery.Type] =
    [
        F14.self,
        Bitstreams.self,
        Matching.self,
        CompressionMicro.self,
        Compression.self,
    ]
    #else
    static
    let all:[any TestBattery.Type] =
    [
        CompressionMicro.self,
        Compression.self
    ]
    #endif
}
