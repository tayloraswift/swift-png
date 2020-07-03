enum Test 
{
    struct Failure:Swift.Error 
    {
        let message:String 
    }
    
    enum Function 
    {
        case void(       ()                       -> Result<Void, Failure>)
        // case string_int2((String, (x:Int, y:Int)) -> Result<Void, Failure>, [(String, (x:Int, y:Int))])
        case string(     (String)                 -> Result<Void, Failure>, [String])
        case int(        (Int)                    -> Result<Void, Failure>, [Int])
    }
}

func test(_ function:Test.Function, cases filter:Set<String>, name:String) -> Void?
{
    var successes:Int                               = 0
    var failures:[(name:String?, message:String)]   = []
    switch function 
    {
    case .void(let function):
        switch function()
        {
        case .success:
            successes += 1
        case .failure(let failure):
            failures.append((nil, failure.message))
        }
    //case .string_int2(let function, let cases):
    //    for arguments:(String, (x:Int, y:Int)) in cases 
    //    {
    //        switch function(arguments.0, arguments.1)
    //        {
    //        case .success:
    //            successes += 1
    //        case .failure(let failure):
    //            failures.append(("('\(arguments.0)', \(arguments.1))", failure.message))
    //        }
    //    }
    case .string(let function, let cases):
        for argument:String in cases where filter.contains(argument) || filter.isEmpty
        {
            switch function(argument)
            {
            case .success:
                successes += 1
            case .failure(let failure):
                failures.append((argument, failure.message))
            }
        }
    case .int(let function, let cases):
        for argument:Int in cases where filter.contains("\(argument)") || filter.isEmpty
        {
            switch function(argument)
            {
            case .success:
                successes += 1
            case .failure(let failure):
                failures.append(("n = \(argument)", failure.message))
            }
        }
    }
    
    var width:Int 
    {
        80
    }
    var white:(Double, Double, Double)
    {
        (1, 1, 1)
    }
    var red:(Double, Double, Double)
    {
        (1, 0.4, 0.3)
    }
    switch (successes, failures.count)
    {
    case (1, 0):
        Highlight.print(.pad(" test \(String.pad("'\(name)'", right: 30)) passed ", right: width), highlight: white)
    case (let succeeded, 0):
        Highlight.print(.pad(" test \(String.pad("'\(name)'", right: 30)) passed \(String.pad("(\(succeeded)", left: 3)) cases)", right: width), highlight: white)
    case (0, 1):
        Highlight.print(.pad(" test \(String.pad("'\(name)'", right: 30)) failed ", right: width), highlight: red)
    case (let succeeded, let failed):
        Highlight.print(.pad(" test \(String.pad("'\(name)'", right: 30)) failed \(String.pad("(\(succeeded + failed)", left: 3)) cases, \(String.pad("\(failed)", left: 2)) failed)", right: width), highlight: red)
    }
    for (i, failure):(Int, (name:String?, message:String)) in failures.enumerated() 
    {
        if let name:String = failure.name 
        {
            Highlight.print(" [\(String.pad("\(i)", left: 2))] case '\(name)' failed: \(failure.message)", color: red)
        }
        else 
        {
            Highlight.print(" [\(String.pad("\(i)", left: 2))]: \(failure.message)", color: red)
        }
    }
    
    return failures.count > 0 ? nil : ()
}
