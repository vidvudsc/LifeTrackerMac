import AppKit
import Foundation

let outputPath: String
switch CommandLine.arguments.count {
case 2:
    outputPath = CommandLine.arguments[1]
case 3:
    outputPath = CommandLine.arguments[2]
default:
    fputs("usage: render_icon.swift [ignored-input.png] output.png\n", stderr)
    exit(2)
}

let outputURL = URL(fileURLWithPath: outputPath)
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(displayP3Red: red, green: green, blue: blue, alpha: alpha)
}

func roundedRect(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

image.lockFocus()

NSColor.clear.setFill()
NSRect(origin: .zero, size: size).fill()

let iconRect = NSRect(x: 82, y: 82, width: 860, height: 860)
let iconPath = roundedRect(iconRect, radius: 190)

NSGraphicsContext.current?.saveGraphicsState()
iconPath.addClip()

NSGradient(colors: [
    color(0.43, 0.36, 0.56),
    color(0.19, 0.18, 0.28),
    color(0.07, 0.08, 0.12)
])?.draw(in: iconRect, angle: -45)

NSColor.white.withAlphaComponent(0.050).setFill()
roundedRect(NSRect(x: 118, y: 600, width: 788, height: 250), radius: 130).fill()

NSColor.black.withAlphaComponent(0.16).setFill()
roundedRect(NSRect(x: 118, y: 126, width: 788, height: 245), radius: 130).fill()

NSGraphicsContext.current?.restoreGraphicsState()

NSColor.white.withAlphaComponent(0.18).setStroke()
iconPath.lineWidth = 2
iconPath.stroke()

NSColor.black.withAlphaComponent(0.16).setStroke()
let innerStroke = roundedRect(iconRect.insetBy(dx: 10, dy: 10), radius: 180)
innerStroke.lineWidth = 2
innerStroke.stroke()

let markRect = NSRect(x: 264, y: 282, width: 496, height: 460)
let glow = NSShadow()
glow.shadowColor = color(0.76, 0.55, 0.95, 0.42)
glow.shadowBlurRadius = 42
glow.shadowOffset = .zero

NSGraphicsContext.current?.saveGraphicsState()
glow.set()
color(0.70, 0.50, 0.92, 0.18).setFill()
NSBezierPath(ovalIn: markRect.insetBy(dx: 28, dy: 28)).fill()
NSGraphicsContext.current?.restoreGraphicsState()

let barShadow = NSShadow()
barShadow.shadowColor = NSColor.black.withAlphaComponent(0.26)
barShadow.shadowBlurRadius = 18
barShadow.shadowOffset = NSSize(width: 0, height: -7)

let heights: [CGFloat] = [190, 315, 420, 300, 235]
let barWidth: CGFloat = 66
let gap: CGFloat = 34
let totalWidth = CGFloat(heights.count) * barWidth + CGFloat(heights.count - 1) * gap
let startX = size.width / 2 - totalWidth / 2
let centerY = size.height / 2

for (index, height) in heights.enumerated() {
    let x = startX + CGFloat(index) * (barWidth + gap)
    let rect = NSRect(x: x, y: centerY - height / 2, width: barWidth, height: height)
    let bar = roundedRect(rect, radius: barWidth / 2)
    NSGraphicsContext.current?.saveGraphicsState()
    barShadow.set()
    let top = color(0.88, 0.70, 1.0, 0.98)
    let bottom = color(0.62, 0.42, 0.84, 0.98)
    NSGradient(colors: [top, bottom])?.draw(in: bar, angle: -90)
    NSGraphicsContext.current?.restoreGraphicsState()

    NSColor.white.withAlphaComponent(index == 2 ? 0.24 : 0.16).setStroke()
    bar.lineWidth = 1.5
    bar.stroke()
}

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    fputs("could not render output PNG\n", stderr)
    exit(1)
}

try png.write(to: outputURL)
