import WorkspaceConfiguration

let configuration:WorkspaceConfiguration = .init()
configuration.proofreading.rules.remove(.unicode)
configuration.proofreading.rules.remove(.colonSpacing)
configuration.documentation.localizations = ["en-US"]
