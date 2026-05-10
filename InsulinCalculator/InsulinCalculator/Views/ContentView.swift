import SwiftUI

struct ContentView: View {
    @StateObject private var historyStore = DoseHistoryStore()
    @StateObject private var viewModel: CalculatorViewModel

    init() {
        let store = DoseHistoryStore()
        _historyStore = StateObject(wrappedValue: store)
        _viewModel = StateObject(wrappedValue: CalculatorViewModel(historyStore: store))
    }

    var body: some View {
        TabView {
            CalculatorView(viewModel: viewModel)
                .tabItem {
                    Label("Calculator", systemImage: "syringe")
                }

            HistoryView(historyStore: historyStore)
                .tabItem {
                    Label("History", systemImage: "clock")
                }

            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(.blue)
    }
}
