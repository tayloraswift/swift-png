import Testing_

@main
enum Main:TestMain
{
    #if DEBUG
    static
    let all:[any TestBattery.Type] =
    [
        Premultiplication.self,
        Filtering.self,
    ]
    #else
    static
    let all:[any TestBattery.Type] =
    [
        Premultiplication.self,
    ]
    #endif
}
