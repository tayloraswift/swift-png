import Foundation
import XCTest

import SDGExternalProcess

class APITests : XCTestCase {

    func testPNG() throws {
        let packageRoot = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        try Shell.default.run(command: ["swift", "build", "--configuration", "release"], in: packageRoot, reportProgress: { print($0) })
        try Shell.default.run(command: [".build/release/tests"], in: packageRoot, reportProgress: { print($0) })
    }
}
