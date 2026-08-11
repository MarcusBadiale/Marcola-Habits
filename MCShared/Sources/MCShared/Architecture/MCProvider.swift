import SwiftUI

public protocol MCProvider: DynamicProperty {}

@propertyWrapper
public struct Provider<T: MCProvider>: DynamicProperty {
    public var wrappedValue: T

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    public init(_ value: T) {
        self.wrappedValue = value
    }
}
