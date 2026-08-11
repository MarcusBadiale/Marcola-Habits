import SwiftUI

struct StatsCalculatorKey: EnvironmentKey {
    static let defaultValue: StatsCalculatorAPI = StatsCalculator()
}

public extension EnvironmentValues {
    var statsCalculator: StatsCalculatorAPI {
        get { self[StatsCalculatorKey.self] }
        set { self[StatsCalculatorKey.self] = newValue }
    }
}
