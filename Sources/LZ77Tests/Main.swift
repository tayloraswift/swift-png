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
        Compression.self,
    ]
    #else
    static
    let all:[any TestBattery.Type] =
    [
        Compression.self
    ]
    #endif
}
