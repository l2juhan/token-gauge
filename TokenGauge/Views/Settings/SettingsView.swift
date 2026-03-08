import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("일반", systemImage: "gear")
                }

            Text("프로바이더 설정 (준비 중)")
                .tabItem {
                    Label("프로바이더", systemImage: "puzzlepiece")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    var body: some View {
        Form {
            Text("TokenGauge v1.0")
                .font(.headline)
            Text("설정 화면은 Phase 1 5주차에 구현됩니다.")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
