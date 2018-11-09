#if os(macOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

// global
var backspaceEnabled:Bool = true

func runTests(_ groups:[Group]) -> Never
{
    //var verbose:Bool        = false
    var testSet:Set<String> = []

    for argument:String in CommandLine.arguments.dropFirst()
    {
        switch argument
        {
            case "-l", "--nobackspace":
                backspaceEnabled = false

            default:
                testSet.insert(argument)
        }
    }

    var passed:Int   = 0,
        failed:Int   = 0,
        expected:Int = 0,
        number:Int   = 0

    let count:Int    = groups.reduce(0){ $0 + $1.count }

    printTestHeader(0, of: count)
    print()
    printProgress(0)
    for group:Group in groups
    {
        var i:Int = 0
        group.forEach(filter: testSet.isEmpty ? nil : testSet)
        {
            (name:String, expectation:Bool, result:String?) in

            i      += 1
            number += 1

            let label:String = "(\(group.name):\(i)) test '\(name)'",
                output:String
            expected += expectation ? 1 : 0
            if let message:String = result
            {
                failed += 1
                output  = "\(Colors.red.1)\(label) failed\(Colors.off.0)"

                if backspaceEnabled
                {
                    upline(3)
                }
                print(output)
                print("\(Colors.red.0)\(indent(message, by: 4))\(Colors.off.0)\n")
            }
            else
            {
                passed += 1
                output  = "\(Colors.green.1)\(label) passed\(Colors.off.0)"

                if backspaceEnabled
                {
                    upline(3)
                }
            }

            printTestHeader(number, of: count)
            printCentered(output)
            printProgress(Double(number) / Double(count))
        }
    }

    if backspaceEnabled
    {
        upline(2)
    }

    let summary:String = "\(Colors.lightCyan.1)\(passed) passed, \(failed) failed\(Colors.off.0)"
    if expected <= passed
    {
        printCentered(summary)
        printProgress(1)
        print()
        printCentered("\(Colors.pink.1)<13\(Colors.off.0)")
        exit(0)
    }
    else
    {
        printCentered("\(summary) \(Colors.off.1)(\(expected - passed) unexpected)\(Colors.off.0)")
        printProgress(1)
        print()
        printCentered("\(Colors.pink.1)</13\(Colors.off.0)")
        exit(-1)
    }
}

runTests(cases)
