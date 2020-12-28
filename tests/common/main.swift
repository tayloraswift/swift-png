import func Foundation.exit

enum Global 
{
    enum Option 
    {
        case compact 
        case printExpectedFailures
    }
    
    static 
    var filters:[String: Set<String>]   = [:], 
        options:Set<Option>             = []
}

for argument:String in CommandLine.arguments.dropFirst() 
{
    if argument.starts(with: "-") 
    {
        switch argument 
        {
        case "--compact", "-c":
            Global.options.insert(.compact)
        case "--print-expected-failures", "-e":
            Global.options.insert(.printExpectedFailures)
        default:
            print("'\(argument)' is not a valid option")
            Foundation.exit(-2)
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
            if let cases:Set<String> = Global.filters[name], !cases.isEmpty 
            {
                Global.filters[name]?.insert(`case`)
            }
            else 
            {
                Global.filters[name] = [`case`]
            }
        }
        else 
        {
            Global.filters[name] = []
        }
    }
}

var failed = false 
for (name, function):(String, Test.Function) in Test.cases 
{
    guard let cases:Set<String> = 
        Global.filters[name] ?? (Global.filters.isEmpty ? [] : nil)
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
