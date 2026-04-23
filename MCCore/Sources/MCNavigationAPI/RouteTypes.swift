import Foundation

public typealias RouteParams = [String: AnyHashable]

public enum TabID: String, CaseIterable, Hashable, Sendable {
    case today, categories, stats, settings
}
