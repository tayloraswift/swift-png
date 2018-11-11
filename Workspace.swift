import WorkspaceConfiguration

let configuration:WorkspaceConfiguration = .init()

// ••••••• General •••••••

// The project appears to only target Linux.
// In any case, it fails to compile on macOS right now.
configuration.supportedOperatingSystems.remove(.macOS)
configuration.supportedOperatingSystems.remove(.iOS)
configuration.supportedOperatingSystems.remove(.watchOS)
configuration.supportedOperatingSystems.remove(.tvOS)

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
