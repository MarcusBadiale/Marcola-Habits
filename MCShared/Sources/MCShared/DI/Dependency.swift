@propertyWrapper
public struct Dependency<T> {

    private let container: DependencyContainer

    public init(container: DependencyContainer = .shared) {
        self.container = container
    }

    public var wrappedValue: T {
        container.resolve(T.self)
    }
}
