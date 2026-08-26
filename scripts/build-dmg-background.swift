#!/usr/bin/env swift

import AppKit
import Foundation

let scriptURL = URL(fileURLWithPath: #filePath).standardizedFileURL
let projectURL = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let sourceURL = projectURL.appendingPathComponent("Resources/DMGBackgroundSource.png")
let outputURL = projectURL.appendingPathComponent("Resources/DMGBackground.png")

guard let sourceImage = NSImage(contentsOf: sourceURL) else {
    fputs("Unable to load DMG background source: \(sourceURL.path)\n", stderr)
    exit(66)
}

let pixelWidth = 900
let pixelHeight = 560
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: pixelWidth,
    pixelsHigh: pixelHeight,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bitmapFormat: [],
    bytesPerRow: 0,
    bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fputs("Unable to create the DMG background canvas.\n", stderr)
    exit(70)
}

let canvas = NSRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight)
let sourceSize = sourceImage.size
let targetAspect = canvas.width / canvas.height
let sourceAspect = sourceSize.width / sourceSize.height
let sourceRect: NSRect

if sourceAspect > targetAspect {
    let width = sourceSize.height * targetAspect
    sourceRect = NSRect(
        x: (sourceSize.width - width) / 2,
        y: 0,
        width: width,
        height: sourceSize.height
    )
} else {
    let height = sourceSize.width / targetAspect
    sourceRect = NSRect(
        x: 0,
        y: (sourceSize.height - height) / 2,
        width: sourceSize.width,
        height: height
    )
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.imageInterpolation = .high
sourceImage.draw(in: canvas, from: sourceRect, operation: .copy, fraction: 1)

func drawLabelPlate(centerX: CGFloat) {
    let width: CGFloat = 160
    let height: CGFloat = 30
    let top: CGFloat = 338
    let rect = NSRect(
        x: centerX - width / 2,
        y: canvas.height - top - height,
        width: width,
        height: height
    )
    let plate = NSBezierPath(roundedRect: rect, xRadius: 10, yRadius: 10)
    NSColor(calibratedRed: 0.91, green: 0.95, blue: 1, alpha: 0.86).setFill()
    plate.fill()
}

drawLabelPlate(centerX: 225)
drawLabelPlate(centerX: 675)

func drawCenteredText(
    _ text: String,
    top: CGFloat,
    height: CGFloat,
    font: NSFont,
    color: NSColor
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
    let rect = NSRect(
        x: 48,
        y: canvas.height - top - height,
        width: canvas.width - 96,
        height: height
    )
    (text as NSString).draw(in: rect, withAttributes: attributes)
}

drawCenteredText(
    "Install Space Swipe Lab",
    top: 48,
    height: 42,
    font: .systemFont(ofSize: 30, weight: .semibold),
    color: .white
)
drawCenteredText(
    "Drag Space Swipe Lab into Applications",
    top: 94,
    height: 30,
    font: .systemFont(ofSize: 18, weight: .medium),
    color: NSColor(calibratedRed: 0.73, green: 0.84, blue: 1, alpha: 1)
)

func makeArrowPath() -> NSBezierPath {
    let path = NSBezierPath()
    path.move(to: NSPoint(x: 355, y: 280))
    path.line(to: NSPoint(x: 545, y: 280))
    path.move(to: NSPoint(x: 515, y: 310))
    path.line(to: NSPoint(x: 545, y: 280))
    path.line(to: NSPoint(x: 515, y: 250))
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    return path
}

let arrow = makeArrowPath()
NSColor(calibratedRed: 0.25, green: 0.84, blue: 1, alpha: 0.18).setStroke()
arrow.lineWidth = 16
arrow.stroke()

NSColor(calibratedRed: 0.68, green: 0.94, blue: 1, alpha: 1).setStroke()
arrow.lineWidth = 6
arrow.stroke()

context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Unable to encode the DMG background.\n", stderr)
    exit(70)
}

do {
    try pngData.write(to: outputURL, options: .atomic)
    print(outputURL.path)
} catch {
    fputs("Unable to write DMG background: \(error)\n", stderr)
    exit(74)
}
