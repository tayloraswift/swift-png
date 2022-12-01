import Foundation

public func commonMain(
    commandLineArguments:[String],
    options:UnsafeMutablePointer<Set<Option>>,
    filters:UnsafeMutablePointer<[String: Set<String>]>,
    testCases:[(name:String, function:Test.Function)]) -> Int32
{
    do {
        (options.pointee, filters.pointee) = try parseArguments(Array(commandLineArguments.dropFirst()))
    } catch {
        Foundation.exit(-2)
    }

    var failed = false
    for (name, function):(String, Test.Function) in testCases
    {
        guard let cases:Set<String> =
                filters.pointee[name] ?? (filters.pointee.isEmpty ? [] : nil)
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
