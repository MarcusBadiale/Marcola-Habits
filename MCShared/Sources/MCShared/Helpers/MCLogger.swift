import OSLog

/// Wrapper fino sobre `os.Logger` com subsystem fixo do app.
///
/// Uso:
/// ```swift
/// private let log = MCLogger(category: "HomeViewModel")
/// log.debug("habits loaded: \(habits.count)")
/// ```
public struct MCLogger: Sendable {

    private let logger: Logger

    public init(category: String) {
        self.logger = Logger(subsystem: MCConstants.appBundleID, category: category)
    }

    public func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    public func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    public func warning(_ message: String) {
        logger.warning("\(message, privacy: .public)")
    }

    public func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
