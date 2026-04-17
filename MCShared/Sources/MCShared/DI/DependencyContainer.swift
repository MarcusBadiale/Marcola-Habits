import Foundation

public final class DependencyContainer: @unchecked Sendable {

    public static let shared = DependencyContainer()

    private var factories: [String: Any] = [:]
    private let lock = NSLock()

    public init() {}

    public func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }
        factories[key(for: type)] = factory
    }

    public func resolve<T>(_ type: T.Type) -> T {
        lock.lock()
        defer { lock.unlock() }
        guard let factory = factories[key(for: type)] as? () -> T else {
            fatalError("❌ DependencyContainer: No registration found for \(type). Register it in AppDependencies.registerAll().")
        }
        return factory()
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        factories.removeAll()
    }

    private func key<T>(for type: T.Type) -> String {
        String(describing: type)
    }
}
