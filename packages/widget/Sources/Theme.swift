import SwiftUI

enum NudgeTheme {
    static let bg = Color(hex: "0A0A0A")
    static let cardBg = Color(hex: "141414")
    static let cardBorder = Color(hex: "1E1E1E")
    static let accent = Color(hex: "FF6B35")
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "8A8A8A")
    static let textDim = Color(hex: "555555")

    static let intentAlarm = Color(hex: "FF6B35")
    static let intentTask = Color(hex: "4ECDC4")
    static let intentNote = Color(hex: "A78BFA")
    static let intentAnswer = Color(hex: "60A5FA")

    static let cardRadius: CGFloat = 12
    static let spacing: CGFloat = 12
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
