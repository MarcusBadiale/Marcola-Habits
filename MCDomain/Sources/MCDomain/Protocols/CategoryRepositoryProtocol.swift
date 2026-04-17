import Foundation

public protocol CategoryRepositoryProtocol: Sendable {
    func reorder(_ ids: [UUID]) async throws
}
