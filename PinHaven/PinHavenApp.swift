import SwiftUI
import SwiftData

@main
@MainActor
struct PinHavenApp: App {
    private let storage: Result<ModelContainer, Error>

    init() { storage = Result { try LocalStore.makeContainer() } }

    var body: some Scene {
        WindowGroup {
            switch storage {
            case .success(let container):
                HomeView().modelContainer(container).tint(.teal)
            case .failure:
                ContentUnavailableView {
                    Label("No se pudo abrir la agenda", systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text("Desbloquea el iPhone y vuelve a abrir la app. Si el problema continúa, conserva la app instalada y consulta al desarrollador. No se borraron tus datos.")
                }
            }
        }
    }
}
