import WorkspaceConfiguration

let configuration:WorkspaceConfiguration = .init()

// General

// The project does not appear to support these platforms.
configuration.supportedOperatingSystems.remove(.iOS)
configuration.supportedOperatingSystems.remove(.watchOS)
configuration.supportedOperatingSystems.remove(.tvOS)

// Management

// This would let Workspace keep the Travis CI configuration up to date with the latest recommended set‐up.
// Since you want “.travis.yml” customized, this is off.
configuration.continuousIntegration.manage = false

// Allows Workspace to create an Xcode project on macOS.
configuration.xcode.manage = true

// XCTest cannot see what is going on it the test subprocess.
configuration.testing.enforceCoverage = false

// Proofreading

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

// Documentation

configuration.documentation.localizations = ["en-US"]

// https://sdggiesbrecht.github.io/Workspace/🇨🇦EN/Types/APIDocumentationConfiguration/Properties/encryptedTravisCIDeploymentKey.html
configuration.documentation.api.encryptedTravisCIDeploymentKey = "ItOmb+XzkETMit+MCuuObTihtzfqdCrsmljxYWsJvicnZEchH0jKNrq2FOkLr4y1wPkzkU7FyCMsN2HRrFoEzaB6jTdybCm4uC11lNqlvCzhR6X3b7XtZydmiFN2lxTJWHiocj4LUlSUklxYAI6WikavU6h1xA19wF8lH+mH05IWQ9sxtW/FE0DGcqiZVCXHDJYDNaeYSDgbj2xzgpmaJ8qiea+CbTQfo5RqYtImDcby/S9NnHoKM8vw3Sxoodj0EtS7sc/T6ZXCHsxJ6v69dMuC25RBwp6vmyAqP5pFU17unB5x1wQo0Wj9wqPU+C2599ACAYS1T091uWNGRO55xgi8c6Npg0Aj89yV8UT8wYZAmfHEvTgEaUfATMG2Whc0nHOm/2sU2R78SfxXOrCKnQvGwWFEq50SWilUHpvUrGExZe4Pk3zlmCogrWweEuiBzlU7RnWA8YgYiC++MOs1LBfoH3Z/e8/k2o/cvS6jU04AGB0kaQBDS2NxaPSYCSpbFt62BdaSkGMdysze7h6028PNIz0fdCVFuMgu78Pjd9SiApjvfoOrJkuw3PHzUEerpgC5rMgx4aWwfUDbs3+YXnrZVaNLScmSMycr67/drFb6QqQC2uSsQvq2PLoldsm8Ct28CnB2UBxj5t1OyZJ1gWF7Il0I1Sfvr0RspxiT9p4="

// #workaround(workspace version 0.14.2, Until Workspace sees several problematic documentation comments.)
// See https://github.com/SDGGiesbrecht/Workspace/issues/209
//
// Alternatively, the offending symbols’ documentation could be converted to the “///” format.
// Then the coverage check would work properly.
// (And the information would not be missing from the rendered documentation.)
configuration.documentation.api.enforceCoverage = false
