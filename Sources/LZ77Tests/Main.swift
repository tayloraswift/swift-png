import Testing

@main
enum Main:TestMain
{
    static
    let all:[any TestBattery.Type] =
    [
        F14.self,
        Bitstreams.self,
        Matching.self,
        Compression.self,
    ]
}
