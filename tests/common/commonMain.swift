import Foundation

public func commonMain(
    options:Set<Option>,
    filters:[String: Set<String>],
    testCases:[(name:String, function:Test.Function)]) -> Int32
{
    var failed = false
    for (name, function):(String, Test.Function) in testCases
    {
        guard let cases:Set<String> =
                filters[name] ?? (filters.isEmpty ? [] : nil)
        else
        {
            continue
        }

        guard let _:Void = test(function, cases: cases, name: name)
        else
        {
            failed = true
            continue
        }
    }

    failed ? Foundation.exit(-1) : Foundation.exit(0)
}
