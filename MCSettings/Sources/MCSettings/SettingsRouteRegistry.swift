import MCNavigationAPI
import MCSettingsAPI
import SwiftUI

public struct SettingsRouteRegistry {

    public static func register(in registry: RouteRegistryAPI) {
        registry.registerRoot(for: .settings) {
            AnyView(SettingsView())
        }

        // Todas `push`: são drill-downs com chevron, e `present` fica reservado pra form/picker
        // modal (navigation.md).
        registry.register(SettingsRoutes.appearance) { _ in
            AnyView(AppearanceView())
        }

        registry.register(SettingsRoutes.exportData) { _ in
            AnyView(ExportDataView())
        }

        registry.register(SettingsRoutes.archivedHabits) { _ in
            AnyView(ArchivedHabitsView())
        }

        // `SettingsRoutes.account` e `.notifications` seguem declaradas na API mas NÃO registradas:
        // o login é inline no AccountCard e notificações é uma row "Coming soon". Registrar sem
        // destino renderizaria "Route not found".
    }
}
