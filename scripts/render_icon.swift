import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("usage: render_icon.swift input-layer.png output.png\n", stderr)
    exit(2)
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])

guard let layer = NSImage(contentsOf: inputURL) else {
    fputs("could not read input image\n", stderr)
    exit(1)
}

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

NSColor.clear.setFill()
NSRect(origin: .zero, size: size).fill()

let canvas = NSRect(x: 0, y: 0, width: size.width, height: size.height)
let rect = canvas.insetBy(dx: 88, dy: 88)
let backgroundPath = NSBezierPath(roundedRect: rect, xRadius: 178, yRadius: 178)
NSGraphicsContext.current?.saveGraphicsState()
backgroundPath.addClip()

let top = NSColor(displayP3Red: 0.95675, green: 0.99728, blue: 1.0, alpha: 1.0)
let bottom = NSColor(displayP3Red: 0.51870, green: 0.78499, blue: 0.96783, alpha: 1.0)
NSGradient(colors: [top, bottom])?.draw(in: rect, angle: -90)

NSGraphicsContext.current?.restoreGraphicsState()

NSColor.black.withAlphaComponent(0.16).setStroke()
backgroundPath.lineWidth = 2
backgroundPath.stroke()

let layerRect = rect.insetBy(dx: 48, dy: 48).offsetBy(dx: -0.5, dy: 0)
NSGraphicsContext.current?.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
shadow.shadowBlurRadius = 34
shadow.shadowOffset = NSSize(width: 0, height: -10)
shadow.set()
layer.draw(in: layerRect, from: .zero, operation: .sourceOver, fraction: 1.0)
NSGraphicsContext.current?.restoreGraphicsState()

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
