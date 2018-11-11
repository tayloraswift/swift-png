import WorkspaceConfiguration

let configuration:WorkspaceConfiguration = .init()

// ••••••• General •••••••

// The project does not appear to support these platforms.
configuration.supportedOperatingSystems.remove(.iOS)
configuration.supportedOperatingSystems.remove(.watchOS)
configuration.supportedOperatingSystems.remove(.tvOS)

// ••••••• Management •••••••

// This lets Workspace keep the Travis CI configuration up to date with the latest recommended set‐up.
// If you need to customize “.travis.yml”, turn this off.
configuration.continuousIntegration.manage = true

// Allows Workspace to create an Xcode project on macOS.
configuration.xcode.manage = true

// XCTest cannot see what is going on it the test subprocess.
configuration.testing.enforceCoverage = false

// ••••••• Proofreading •••••••

// These are documented at https://sdggiesbrecht.github.io/Workspace/🇨🇦EN/Types/ProofreadingRule.html

configuration.proofreading.rules.remove(.unicode)
configuration.proofreading.rules.remove(.colonSpacing)

// Disabled because there are violations.
// For an explanation, see: https://forums.swift.org/t/introducing-documentation-generation-for-swift-packages/15971/8?u=sdggiesbrecht
configuration.proofreading.rules.remove(.compatibilityCharacters)

// The rules may conflict with the PNG project style:
// Would require parameter callouts to be grouped.
configuration.proofreading.rules.remove(.parameterGrouping)
// Would require repeated line‐style documentation instead of block‐style,
// which is vulnerable to Xcode’s autoindent destroying semantic Markdown indents.
configuration.proofreading.rules.remove(.autoindentResilience)

// ••••••• Documentation •••••••

configuration.documentation.localizations = ["en-US"]

// https://sdggiesbrecht.github.io/Workspace/🇨🇦EN/Types/APIDocumentationConfiguration/Properties/encryptedTravisCIDeploymentKey.html
configuration.documentation.api.encryptedTravisCIDeploymentKey = "You’ll have to encrypt one yourself and provide it here."

// #workaround(workspace version 0.14.2, Until Workspace sees several problematic documentation comments.)
// See https://github.com/SDGGiesbrecht/Workspace/issues/209
//
// Alternatively, the offending symbols’ documentation could be converted to the “///” format.
// Then the coverage check would work properly.
// (And the information would not be missing from the rendered documentation.)
configuration.documentation.api.enforceCoverage = false
