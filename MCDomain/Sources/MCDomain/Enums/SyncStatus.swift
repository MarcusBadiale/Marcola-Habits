public enum SyncStatus: String, Codable, Sendable {
    case synced, pendingUpload, pendingDelete, conflict
}
