// Genera el icono de PoxiNTFS con la receta de los logos Poxi:
// baldosa oscura, "P" gruesa de bloques con ojo cuadrado, sombra escalonada en 2 capas
// y un objeto pixel-art abajo a la derecha (aquí, un disco duro).
// Todo se dibuja en un lienzo de 512x512 con la misma cuadrícula que el logo de PoxiClicker.
import AppKit

let canvas = 1024
guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: canvas, pixelsHigh: canvas, bitsPerSample: 8,
    samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: rep) else { fatalError("sin contexto") }

func rgb(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context

// Origen arriba a la izquierda; la baldosa de 512 se pinta en 824px con margen de 100 (formato macOS).
let transform = NSAffineTransform()
transform.translateX(by: 100, yBy: 924)
transform.scaleX(by: 824.0 / 512.0, yBy: -824.0 / 512.0)
transform.concat()

// Baldosa
rgb(0x0A111F).setFill()
NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 512, height: 512), xRadius: 92, yRadius: 92).fill()

// La "P": 10 x 12 bloques de 25,6px, origen en el bloque (4, 3).
let unit: CGFloat = 25.6
let originX = 4 * unit, originY = 3 * unit
let rows = [
    "XXXXXXXXXX",
    "XXXXXXXXXX",
    "XXX....XXX",
    "XXX....XXX",
    "XXX....XXX",
    "XXXXXXXXXX",
    "XXXXXXXXXX",
    "XXX.......",
    "XXX.......",
    "XXX.......",
    "XXX.......",
    "XXX.......",
]

func fill(_ pattern: [String], at x0: CGFloat, _ y0: CGFloat, cell: CGFloat, color: NSColor) {
    let path = NSBezierPath()
    for (y, row) in pattern.enumerated() {
        for (x, char) in row.enumerated() where char != "." {
            path.appendRect(NSRect(x: x0 + CGFloat(x) * cell, y: y0 + CGFloat(y) * cell, width: cell, height: cell))
        }
    }
    color.setFill()
    path.fill()
}

// Sombra en dos capas y luego la P por delante.
fill(rows, at: originX + 24, originY + 24, cell: unit, color: rgb(0x5C4414))
fill(rows, at: originX + 12, originY + 12, cell: unit, color: rgb(0xA97B16))
fill(rows, at: originX, originY, cell: unit, color: rgb(0xFFCE3A))

// Lápiz pixel-art en diagonal ("escribir"): 8 x 8 celdas. t = x - y recorre el lápiz; w = x + y lo ensancha.
let cell: CGFloat = 21
let penX: CGFloat = 296, penY: CGFloat = 312
var layers: [UInt32: NSBezierPath] = [:]
let shadow = NSBezierPath()
for y in 0..<8 {
    for x in 0..<8 where (6...8).contains(x + y) {
        let t = x - y, w = x + y
        let hex: UInt32
        switch t {
        case 5...: hex = 0xFF7A8A
        case 3...4: hex = 0xB8C4DD
        case -2...2: hex = w == 6 ? 0xFFFFFF : (w == 7 ? 0xD4DEF0 : 0x8A9BBE)
        case -5...(-3): hex = w == 8 ? 0xC99A62 : 0xF2C58E
        default: hex = 0x3A4663
        }
        let rect = NSRect(x: penX + CGFloat(x) * cell, y: penY + CGFloat(y) * cell, width: cell, height: cell)
        let layer = layers[hex] ?? NSBezierPath()
        layer.appendRect(rect)
        layers[hex] = layer
        shadow.appendRect(rect.offsetBy(dx: 11, dy: 11))
    }
}
rgb(0x2A3350).setFill()
shadow.fill()
for (hex, path) in layers {
    rgb(hex).setFill()
    path.fill()
}

NSGraphicsContext.restoreGraphicsState()
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
