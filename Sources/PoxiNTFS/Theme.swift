import SwiftUI
import AppKit

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

enum Theme {
    static let background = Color(hex: 0x0A0E1C)
    static let yellow = Color(hex: 0xFFCE3A)
    static let gold = Color(hex: 0xFFA928)
    static let ink = Color(hex: 0x0A111F)
    static let text = Color(hex: 0xE8ECF8)
    static let muted = Color(hex: 0x8A93AD)
    static let green = Color(hex: 0x34D399)
    static let info = Color(hex: 0x60A5FA)
    static let warn = Color(hex: 0xFB923C)
    static let red = Color(hex: 0xF87171)

    static let accent = LinearGradient(colors: [yellow, gold], startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct BackgroundView: View {
    var body: some View {
        ZStack {
            Theme.background
            RadialGradient(colors: [Theme.yellow.opacity(0.11), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 520)
            RadialGradient(colors: [Theme.gold.opacity(0.06), .clear], center: .topLeading, startRadius: 0, endRadius: 420)
        }
        .ignoresSafeArea()
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04)))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }
}

extension View {
    func card() -> some View { modifier(CardStyle()) }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 16)
            .frame(height: 34)
            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.accent))
            .shadow(color: Theme.yellow.opacity(0.28), radius: 10, y: 3)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(configuration.isPressed ? 0.12 : 0.06)))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
    }
}

struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold))
            .tracking(1.3)
            .foregroundStyle(Theme.muted)
    }
}

struct Pill: View {
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(text).font(.system(size: 12, weight: .semibold)).foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .frame(height: 26)
        .background(Capsule().fill(color.opacity(0.13)))
        .overlay(Capsule().strokeBorder(color.opacity(0.25), lineWidth: 1))
    }
}

/// La "P" pixel-art de las apps Poxi: bloques gruesos, ojo cuadrado y sombra escalonada en 2 capas.
/// Mismo dibujo que el icono (scripts/make-icon.swift).
struct PixelLogo: View {
    var height: CGFloat = 20
    static let color = Color(hex: 0xFFCE3A)
    private static let rows = [
        "XXXXXXXXXX", "XXXXXXXXXX", "XXX....XXX", "XXX....XXX", "XXX....XXX", "XXXXXXXXXX",
        "XXXXXXXXXX", "XXX.......", "XXX.......", "XXX.......", "XXX.......", "XXX.......",
    ]

    var body: some View {
        Canvas { context, size in
            let cell = size.height / (CGFloat(Self.rows.count) + 0.94)
            func draw(offset: CGFloat, color: Color) {
                var path = Path()
                for (y, row) in Self.rows.enumerated() {
                    for (x, char) in row.enumerated() where char == "X" {
                        path.addRect(CGRect(x: CGFloat(x) * cell + offset, y: CGFloat(y) * cell + offset, width: cell, height: cell))
                    }
                }
                context.fill(path, with: .color(color))
            }
            draw(offset: cell * 0.94, color: Color(hex: 0x5C4414))
            draw(offset: cell * 0.47, color: Color(hex: 0xA97B16))
            draw(offset: 0, color: Self.color)
        }
        .frame(width: height * 10.94 / 12.94, height: height)
    }
}

/// Deja la ventana sin barra de título visible y arrastrable desde cualquier parte.
struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.backgroundColor = NSColor(red: 10 / 255, green: 14 / 255, blue: 28 / 255, alpha: 1)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
