import SwiftUI

enum NudgeTheme {
    static let bg = Color(hex: "0A0A0A")
    static let sidebar = Color(hex: "0D0D0D")
    static let cardBg = Color(hex: "141414")
    static let surfaceHover = Color(hex: "1C1C1C")
    static let cardBorder = Color(hex: "262626")
    static let borderStrong = Color(hex: "404040")
    static let accent = Color(hex: "FF6B35")
    static let accentHover = Color(hex: "FF8255")
    static let textPrimary = Color(hex: "EDEDED")
    static let textSecondary = Color(hex: "A3A3A3")
    static let textDim = Color(hex: "737373")

    static let success = Color(hex: "22C55E")
    static let warning = Color(hex: "EAB308")
    static let error = Color(hex: "EF4444")

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
