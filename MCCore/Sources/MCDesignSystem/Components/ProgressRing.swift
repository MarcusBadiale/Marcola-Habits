import SwiftUI

public struct ProgressRing: View {
    public let progress: Double
    public var lineWidth: CGFloat
    public var color: Color

    public init(progress: Double, lineWidth: CGFloat = 4, color: Color = MCColors.accent) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.color = color
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.4), value: progress)
        }
    }
}

#Preview {
    HStack(spacing: MCSpacing.xl) {
        ProgressRing(progress: 0.3, color: MCColors.health)
            .frame(width: 44, height: 44)
        ProgressRing(progress: 0.7, color: MCColors.productivity)
            .frame(width: 44, height: 44)
        ProgressRing(progress: 1.0, color: MCColors.success)
            .frame(width: 44, height: 44)
    }
    .padding()
}
