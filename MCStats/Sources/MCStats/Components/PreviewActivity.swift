import Foundation
import MCDomain

/// Dados sintéticos para os `#Preview` dos componentes de atividade — sem SwiftData no meio.
enum PreviewActivity {

    /// `count` dias terminando hoje, com um padrão fixo de estados (nada aleatório, pro preview
    /// não mudar a cada redesenho).
    static func days(count: Int) -> [DayActivityDTO] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        return (0..<count).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let weekday = calendar.component(.weekday, from: date)
            let state: ActivityState = {
                if weekday == 1 || weekday == 7 { return .notScheduled }
                return offset % 4 == 2 ? .missed : .completed
            }()
            return DayActivityDTO(date: date, state: state)
        }
    }
}
