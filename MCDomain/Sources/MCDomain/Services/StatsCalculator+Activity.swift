import Foundation

public extension StatsCalculator {

    /// Matriz hábito × dia do período. Uma entrada por hábito recebido, na ordem recebida;
    /// cada entrada com exatamente um `DayActivityDTO` por dia do período, do mais antigo até hoje.
    func activity(logs: [HabitLogDTO], habits: [HabitDTO], days: Int) -> [HabitActivityDTO] {
        let period = periodDays(days: days)
        let completedDays = completedDaysByHabit(logs: logs)

        return habits.map { habit in
            let done = completedDays[habit.id] ?? []

            return HabitActivityDTO(
                habitID: habit.id,
                days: period.map { day in
                    let state: ActivityState
                    if done.contains(day) {
                        state = .completed
                    } else {
                        state = hasObligation(habit.frequency, on: day) ? .missed : .notScheduled
                    }
                    return DayActivityDTO(date: day, state: state)
                }
            )
        }
    }
}
