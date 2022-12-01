import Foundation

public enum Option
{
    case compact
    case printExpectedFailures
}

public enum ParseError: String, LocalizedError
{
    case notValidOption = "Not Valid Option"
    public var errorDescription: String? { self.rawValue }
}

public func parseArguments(_ arguments:[String]) throws -> (options:Set<Option>, filters:[String: Set<String>]) {
    var options:Set<Option> = Set()
    var filters:[String: Set<String>] = [:]
    for argument:String in arguments
    {
        if argument.starts(with: "-")
        {
            switch argument
            {
            case "--compact", "-c":
                options.insert(.compact)
            case "--print-expected-failures", "-e":
                options.insert(.printExpectedFailures)
            default:
                print("'\(argument)' is not a valid option")
                throw ParseError.notValidOption
            }
        }
        else
        {
            let fragments:[String] = argument.split(separator: ":").map(String.init(_:))
            guard let name:String = fragments.first, fragments.count <= 2
            else
            {
                print("'\(argument)' is not a valid test case filter")
                Foundation.exit(-2)
            }

            if let `case`:String = fragments.dropFirst().first
            {
                if let cases:Set<String> = filters[name], !cases.isEmpty
                {
                    filters[name]?.insert(`case`)
                }
                else
                {
                    filters[name] = [`case`]
                }
            }
            else
            {
                filters[name] = []
            }
        }
    }
    return (options:options, filters:filters)
}
