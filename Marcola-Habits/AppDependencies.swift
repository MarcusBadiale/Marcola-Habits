import MCDomain
import MCShared
import MCSync
import MCSyncAPI

enum AppDependencies {
    static func registerAll() {
        let container = DependencyContainer.shared

        container.register(StatsCalculatorAPI.self) {
            StatsCalculator()
        }

        container.register(SyncServiceAPI.self) {
            NoOpSyncEngine()
        }
    }
}
