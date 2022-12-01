import func Foundation.exit
import _PNGTestsCommon

enum Global
{
    static
    var filters:[String: Set<String>]   = [:],
        options:Set<Option>             = []
}

do {
    (Global.options, Global.filters) = try parseArguments(Array(CommandLine.arguments.dropFirst()))
} catch {
    Foundation.exit(-2)
}

Foundation.exit(
    commonMain(
        options: Global.options,
        filters: Global.filters,
        testCases: Test.cases
    )
)
