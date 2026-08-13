import Foundation

enum AppVersion {

    /// `bundle` é parâmetro pra ser testável: dentro de um test target, `Bundle.main` é o runner
    /// do xctest e não o app.
    static func display(bundle: Bundle = .main) -> String {
        let short = bundle.infoDictionary?["CFBundleShortVersionString"] as? String
        let build = bundle.infoDictionary?["CFBundleVersion"] as? String

        return switch (short, build) {
        case let (short?, build?): "\(short) (\(build))"
        case let (short?, nil): short
        default: "—"
        }
    }
}
