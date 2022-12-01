import func Foundation.exit
import _PNGTestsCommon

enum Global
{
    static
    var filters:[String: Set<String>]   = [:],
        options:Set<Option>             = []
}

Foundation.exit(
    commonMain(
        commandLineArguments: CommandLine.arguments,
        options: &Global.options,
        filters: &Global.filters,
        testCases: Test.cases
    )
)

