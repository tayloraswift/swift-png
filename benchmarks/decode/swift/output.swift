#if os(macOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

enum Colors
{
    static
    let off         = ("\u{001B}[0m"   , "\u{001B}[1m"),
        green       = ("\u{001B}[0;32m", "\u{001B}[1;32m"),
        lightGreen  = ("\u{001B}[0;92m", "\u{001B}[1;92m"),
        lightCyan   = ("\u{001B}[0;96m", "\u{001B}[1;96m"),
        red         = ("\u{001B}[0;31m", "\u{001B}[1;31m"),
        pink        = ("\u{001B}[38;5;204m", "\u{001B}[1m\u{001B}[38;5;204m")
}

let TERM_WIDTH:Int = 72

func printCentered(_ string:String, width:Int = TERM_WIDTH)
{
    var count:Int    = 0
    var escaped:Bool = false
    for character:Character in string
    {
        if escaped
        {
            if character == "m"
            {
                escaped = false
            }

            continue
        }
        else
        {
            if character == "\u{001B}"
            {
                escaped = true
                continue
            }
        }

        count += 1
    }

    print(String(repeating: " ", count: max(0, (width - count)) >> 1) + string)
}

func upline(_ n:Int = 1)
{
    print(String(repeating: "\u{001B}[1A\u{001B}[K", count: n), terminator: "")
}

func indent(_ string:String, by indentation:Int) -> String
{
    let indent:String = .init(repeating: " ", count: indentation)
    return indent + string.split(separator: "\n").joined(separator: "\n\(indent)")
}

func printTestHeader(_ i:Int, of count:Int)
{
    printCentered("\(Colors.lightCyan.1)—— Testing: \(i) of \(count) tests ——\(Colors.off.0)")
}

func printProgress(_ percent:Double, width:Int = TERM_WIDTH)
{
    let barWidth:Int = width - 8
    let percentLabel:String = "\(Int(percent * 100))%"
    let percentPadding:String = String(repeating: " ", count: 5 - percentLabel.count)

    print("\(percentPadding)\(percentLabel) \(Colors.lightGreen.0)[\(Colors.lightGreen.1)", terminator: "")
    let barSegments:Int = Int(percent * Double(barWidth))
    print(String(repeating: "=", count: barSegments) + String(repeating: "-", count: barWidth - barSegments), terminator: "")
    print("\(Colors.lightGreen.0)]\(Colors.off.0)")
    fflush(stdout)
}

func formatInt(_ integer:Int, separator:String = ",") -> String
{
    let monolith:String = .init(integer)
    let incomplete:Int  = monolith.count % 3

    var index:String.Index = monolith.startIndex,
        next:String.Index  = monolith.index(index, offsetBy: incomplete)
    var groups:[Substring] = incomplete == 0 ? [] : [monolith[index ..< next]]

    for _ in 0 ..< monolith.count / 3
    {
        index = next
        next  = monolith.index(index, offsetBy: 3)
        groups.append(monolith[index ..< next])
    }

    return groups.joined(separator: separator)
}
