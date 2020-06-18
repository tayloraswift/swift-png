import func Foundation.exit

let filters:[String: Set<String>] = [String: [(name:String, case:String?)]].init(grouping: 
    CommandLine.arguments.dropFirst().map 
{
    (pattern:String) -> (name:String, case:String?) in 
    let fragments:[String] = pattern.split(separator: ":").map(String.init(_:))
    guard let name:String = fragments.first, fragments.count <= 2
    else 
    {
        print("'\(pattern)' is not a valid test case filter")
        Foundation.exit(-2)
    }
    return (name, fragments.dropFirst().first)
}, by: \.name).mapValues 
{
    $0.allSatisfy{ $0.case != nil } ? .init($0.compactMap(\.case)) : []
}

var failed = false 
for (name, function):(String, Test.Function) in Test.cases 
{
    guard let cases:Set<String> = filters[name] ?? (filters.isEmpty ? [] : nil)
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
