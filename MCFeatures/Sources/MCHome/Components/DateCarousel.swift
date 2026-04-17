import MCDesignSystem
import MCShared
import SwiftUI

struct DateCarousel: View {
    @Binding var selectedDate: Date

    private let dayRange = -7...7

    private var dates: [Date] {
        dayRange.map { offset in
            Calendar.current.date(byAdding: .day, value: offset, to: Date.now)!.startOfDay
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MCSpacing.sm) {
                    ForEach(dates, id: \.self) { date in
                        DateItem(date: date, isSelected: date.isInSameDay(selectedDate))
                            .id(date)
                            .onTapGesture { selectedDate = date }
                    }
                }
                .padding(.horizontal, MCSpacing.md)
            }
            .onAppear {
                proxy.scrollTo(selectedDate.startOfDay, anchor: .center)
            }
            .onChange(of: selectedDate) { _, newValue in
                withAnimation {
                    proxy.scrollTo(newValue.startOfDay, anchor: .center)
                }
            }
        }
        .padding(.vertical, MCSpacing.sm)
        .accessibilityIdentifier("home-date-carousel")
    }
}

private struct DateItem: View {
    let date: Date
    let isSelected: Bool

    var body: some View {
        VStack(spacing: MCSpacing.xxs) {
            Text(date.weekdayShortName.uppercased())
                .font(MCTypography.captionSecondary)
                .foregroundStyle(isSelected ? .white : .secondary)

            Text("\(Calendar.current.component(.day, from: date))")
                .font(MCTypography.headline)
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .frame(width: 48, height: 56)
        .background(
            isSelected ? MCColors.accent : Color.clear,
            in: RoundedRectangle(cornerRadius: MCSpacing.cardCornerRadius)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MCSpacing.cardCornerRadius)
                .strokeBorder(date.isToday && !isSelected ? MCColors.accent : .clear, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
