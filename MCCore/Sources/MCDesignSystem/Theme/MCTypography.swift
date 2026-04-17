import SwiftUI

public enum MCTypography {

    public static let largeTitle: Font = .largeTitle.weight(.bold)
    public static let title: Font = .title2.weight(.semibold)
    public static let headline: Font = .headline
    public static let body: Font = .body
    public static let callout: Font = .callout
    public static let caption: Font = .caption
    public static let captionSecondary: Font = .caption2

    public static let streakCount: Font = .system(.title3, design: .rounded, weight: .bold)
    public static let progressLabel: Font = .system(.caption, design: .rounded, weight: .semibold)
}
