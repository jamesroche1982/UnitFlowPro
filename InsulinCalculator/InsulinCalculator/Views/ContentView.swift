import SwiftUI

struct ContentView: View {
    @StateObject private var historyStore = DoseHistoryStore()
    @StateObject private var presetStore = MealPresetStore()
    @StateObject private var viewModel: CalculatorViewModel

    init() {
        let history = DoseHistoryStore()
        let presets = MealPresetStore()
        _historyStore = StateObject(wrappedValue: history)
        _presetStore = StateObject(wrappedValue: presets)
        _viewModel = StateObject(wrappedValue: CalculatorViewModel(historyStore: history, presetStore: presets))
    }

    var body: some View {
        TabView {
            CalculatorView(viewModel: viewModel)
                .tabItem { Label("Calculator", systemImage: "syringe") }

            HistoryView(historyStore: historyStore, glucoseUnit: viewModel.settings.glucoseUnit)
                .tabItem { Label("History", systemImage: "clock") }

            SettingsView(viewModel: viewModel)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(.blue)
        .preferredColorScheme(viewModel.settings.appColorScheme.colorScheme)
        .onAppear { viewModel.requestHealthKitPermission() }
    }
}
