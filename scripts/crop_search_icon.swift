import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("usage: crop_search_icon.swift input.png output.png\n", stderr)
    exit(2)
}

let input = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2])

guard
    let image = NSImage(contentsOf: input),
    let tiff = image.tiffRepresentation,
    let rep = NSBitmapImageRep(data: tiff)
else {
    fputs("could not read input image\n", stderr)
    exit(1)
}

var minX = rep.pixelsWide
var minY = rep.pixelsHigh
var maxX = -1
var maxY = -1

for y in 0..<rep.pixelsHigh {
    for x in 0..<rep.pixelsWide {
        let alpha = rep.colorAt(x: x, y: y)?.alphaComponent ?? 0
        if alpha > 0.03 {
            minX = min(minX, x)
            minY = min(minY, y)
            maxX = max(maxX, x)
            maxY = max(maxY, y)
        }
    }
}

guard maxX >= minX, maxY >= minY else {
    fputs("input image has no visible pixels\n", stderr)
    exit(1)
}

let padding = 8
minX = max(0, minX - padding)
minY = max(0, minY - padding)
maxX = min(rep.pixelsWide - 1, maxX + padding)
maxY = min(rep.pixelsHigh - 1, maxY + padding)

let cropWidth = maxX - minX + 1
let cropHeight = maxY - minY + 1
let side = max(cropWidth, cropHeight)
let canvas = NSImage(size: NSSize(width: side, height: side))
canvas.lockFocus()
NSColor.clear.setFill()
NSRect(x: 0, y: 0, width: side, height: side).fill()

let drawX = CGFloat((side - cropWidth) / 2)
let drawY = CGFloat((side - cropHeight) / 2)
image.draw(
    in: NSRect(x: drawX, y: drawY, width: CGFloat(cropWidth), height: CGFloat(cropHeight)),
    from: NSRect(x: CGFloat(minX), y: CGFloat(minY), width: CGFloat(cropWidth), height: CGFloat(cropHeight)),
    operation: .sourceOver,
    fraction: 1
)
canvas.unlockFocus()

guard
    let outTiff = canvas.tiffRepresentation,
    let outRep = NSBitmapImageRep(data: outTiff),
    let png = outRep.representation(using: .png, properties: [:])
else {
    fputs("could not write output image\n", stderr)
    exit(1)
}

try png.write(to: output)
