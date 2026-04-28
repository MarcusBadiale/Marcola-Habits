import MCDomain
import MCShared

public enum DemoDependencies {
    public static func registerAll() {
        let container = DependencyContainer.shared

        container.register(StatsCalculatorAPI.self) {
            StatsCalculator()
        }
    }
}
