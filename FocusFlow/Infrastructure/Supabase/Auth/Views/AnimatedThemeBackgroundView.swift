import SwiftUI

struct AnimatedThemeBackgroundView: View {
    @ObservedObject private var appSettings = AppSettings.shared
    @State private var themeIndex: Int = 0

    private var themes: [AppTheme] {
        AppTheme.allCases
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: themes[themeIndex].backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 6), value: themeIndex)
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { _ in
                withAnimation {
                    themeIndex = (themeIndex + 1) % themes.count
                }
            }
        }
    }
}
