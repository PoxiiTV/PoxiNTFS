// Genera el banner del README (2560x760) con el estilo de la familia Poxi:
// fondo con cuadrícula, panel con sombra pixel, logo + título, etiquetas y captura de la app con un sello.
// Uso: make-banner <icono.png> <captura.png> <salida.png>
import SwiftUI
import AppKit

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

let yellow = Color(hex: 0xFFCE3A)
let edge = Color(hex: 0x2A3446)
let panel = Color(hex: 0x111827)
let hardShadow = Color(hex: 0x04070D)

struct Grid: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            stride(from: 0, through: size.width, by: 40).forEach { path.addRect(CGRect(x: $0, y: 0, width: 1, height: size.height)) }
            stride(from: 0, through: size.height, by: 40).forEach { path.addRect(CGRect(x: 0, y: $0, width: size.width, height: 1)) }
            context.fill(path, with: .color(.white.opacity(0.035)))
        }
    }
}

struct PixelBox<Content: View>: View {
    var shadow: CGFloat = 8
    var fill = panel
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(fill)
            .overlay(Rectangle().strokeBorder(edge, lineWidth: 3))
            .background(hardShadow.offset(x: shadow, y: shadow))
    }
}

struct Chip: View {
    let text: String
    let color: Color

    var body: some View {
        PixelBox(shadow: 5, fill: Color(hex: 0x0D1320)) {
            HStack(spacing: 14) {
                Rectangle().fill(color).frame(width: 13, height: 13)
                Text(text)
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .tracking(2.4)
                    .foregroundStyle(Color(hex: 0xEEF2FB))
            }
            .padding(.horizontal, 20)
            .frame(height: 50)
        }
    }
}

struct Banner: View {
    let icon: NSImage
    let screenshot: NSImage

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(hex: 0x0A111F)
            Grid()
            RadialGradient(colors: [yellow.opacity(0.08), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 700)

            PixelBox {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 26) {
                        Image(nsImage: icon).resizable().interpolation(.none).frame(width: 150, height: 150)
                            .padding(-20)
                        (Text("Poxi").foregroundColor(Color(hex: 0xF4F6FB)) + Text("NTFS").foregroundColor(yellow))
                            .font(.system(size: 112, weight: .black, design: .rounded))
                            .shadow(color: hardShadow, radius: 0, x: 6, y: 6)
                    }
                    Text("Escribe en discos de Windows desde tu Mac")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: 0x9AA6BD))
                        .padding(.top, 26)
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 20) {
                            Chip(text: "LEE Y ESCRIBE NTFS", color: yellow)
                            Chip(text: "EN CASTELLANO", color: Color(hex: 0x60A5FA))
                        }
                        HStack(spacing: 20) {
                            Chip(text: "GRATIS", color: Color(hex: 0x34D399))
                            Chip(text: "SIN ANUNCIOS", color: Color(hex: 0xF472B6))
                            Chip(text: "OPEN SOURCE", color: Color(hex: 0xA78BFA))
                        }
                    }
                    .padding(.top, 44)
                }
                .padding(.horizontal, 54)
                .padding(.vertical, 50)
                .frame(width: 1080, alignment: .leading)
            }
            .offset(x: 82, y: 82)

            // Captura de la app, recortada a la parte de arriba
            PixelBox(shadow: 10, fill: Color(hex: 0x0A0E1C)) {
                Image(nsImage: screenshot)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 1140, height: 935, alignment: .top)
                    .frame(width: 1140, height: 560, alignment: .top)
                    .clipped()
            }
            .offset(x: 1316, y: 70)

            PixelBox(shadow: 7, fill: yellow) {
                Text("✎  LEE + ESCRIBE")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color(hex: 0x0A111F))
                    .padding(.horizontal, 30)
                    .frame(height: 82)
            }
            .offset(x: 2070, y: 600)
        }
        .frame(width: 2560, height: 760)
        .clipped()
    }
}

@main
enum Main {
    @MainActor static func main() {
        _ = NSApplication.shared
        let args = CommandLine.arguments
        guard args.count == 4, let icon = NSImage(contentsOfFile: args[1]), let shot = NSImage(contentsOfFile: args[2]) else {
            print("Uso: make-banner <icono.png> <captura.png> <salida.png>"); exit(1)
        }
        let renderer = ImageRenderer(content: Banner(icon: icon, screenshot: shot))
        renderer.scale = 1
        guard let tiff = renderer.nsImage?.tiffRepresentation,
              let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else {
            print("No se pudo renderizar"); exit(1)
        }
        try! png.write(to: URL(fileURLWithPath: args[3]))
        print("Banner: \(args[3])")
    }
}
