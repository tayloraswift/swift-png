import WorkspaceConfiguration

let configuration:WorkspaceConfiguration = .init()

// ••••••• Proofreading •••••••

configuration.proofreading.rules.remove(.unicode)
configuration.proofreading.rules.remove(.colonSpacing)

// ••••••• Documentation •••••••

configuration.documentation.localizations = ["en-US"]
