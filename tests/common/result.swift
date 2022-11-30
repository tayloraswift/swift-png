import PNG

public enum Test
{
    public struct Failure:Swift.Error
    {
        public let message:String

        public init(message: String) {
            self.message = message
        }
    }
    
    public enum Function
    {
        case void(       ()                       -> Result<Void, Failure>)
        // case string_int2((String, (x:Int, y:Int)) -> Result<Void, Failure>, [(String, (x:Int, y:Int))])
        case string(     (String)                 -> Result<Void, Failure>, [String])
        case int(        (Int)                    -> Result<Void, Failure>, [Int])
    }
    
    // prints an image using terminal colors 
    public
    static
    func terminal<T>(image rgb:[PNG.RGBA<T>], size:(x:Int, y:Int)) -> String
        where T:FixedWidthInteger & UnsignedInteger
    {
        let downsample:Int = min(max(1, size.x / 16), max(1, size.y / 16))
        return stride(from: 0, to: size.y, by: downsample).map
        {
            (i:Int) -> String in 
            stride(from: 0, to: size.x, by: downsample).map 
            {
                (j:Int) in 
                
                // downsampling 
                var r:Int = 0, 
                    g:Int = 0, 
                    b:Int = 0 
                for y:Int in i ..< min(i + downsample, size.y) 
                {
                    for x:Int in j ..< min(j + downsample, size.x)
                    {
                        let c:PNG.RGBA<T> = rgb[x + y * size.x]
                        r += .init(c.r)
                        g += .init(c.g)
                        b += .init(c.b)
                    }
                }
                
                let count:Int = 
                    (min(i + downsample, size.y) - i) * 
                    (min(j + downsample, size.x) - j)
                let color:(r:Double, g:Double, b:Double) = 
                (
                    .init(r) / (.init(T.max) * .init(count)),
                    .init(g) / (.init(T.max) * .init(count)),
                    .init(b) / (.init(T.max) * .init(count))
                )
                return .highlight("  ", bg: color)
            }.joined()
        }.joined(separator: "\n")
    }
}

public
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
        print(String.highlight(.pad(" test \(String.pad("'\(name)'", right: 30)) passed ", right: width), 
            bg: white))
    case (let succeeded, 0):
        print(String.highlight(.pad(" test \(String.pad("'\(name)'", right: 30)) passed \(String.pad("(\(succeeded)", left: 3)) cases)", right: width), 
            bg: white))
    case (0, 1):
        print(String.highlight(.pad(" test \(String.pad("'\(name)'", right: 30)) failed ", right: width), 
            bg: red))
    case (let succeeded, let failed):
        print(String.highlight(.pad(" test \(String.pad("'\(name)'", right: 30)) failed \(String.pad("(\(succeeded + failed)", left: 3)) cases, \(String.pad("\(failed)", left: 2)) failed)", right: width), 
            bg: red))
    }
    for (i, failure):(Int, (name:String?, message:String)) in failures.enumerated() 
    {
        if let name:String = failure.name 
        {
            print(String.highlight(" [\(String.pad("\(i)", left: 2))] case '\(name)' failed: \(failure.message)", 
                bg: red))
        }
        else 
        {
            print(String.highlight(" [\(String.pad("\(i)", left: 2))]: \(failure.message)", 
                bg: red))
        }
    }
    
    return failures.count > 0 ? nil : ()
}
