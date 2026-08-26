#!/usr/bin/env swift

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

guard CommandLine.arguments.count == 3 else {
    FileHandle.standardError.write(
        Data("Usage: render-icon.swift source.png output.iconset\n".utf8)
    )
    exit(64)
}

let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)

guard
    let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
    let sourceImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
else {
    FileHandle.standardError.write(Data("Could not decode icon source\n".utf8))
    exit(65)
}

let outputs: [(pixels: Int, filename: String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1_024, "icon_512x512@2x.png")
]

func superellipsePath(size: CGFloat) -> CGPath {
    let path = CGMutablePath()
    let center = size / 2
    let radius = size * 0.46
    let exponent = 2.0 / 5.0

    for step in 0...360 {
        let angle = Double(step) * .pi * 2 / 360
        let cosine = cos(angle)
        let sine = sin(angle)
        let x = center + radius * copysign(pow(abs(cosine), exponent), cosine)
        let y = center + radius * copysign(pow(abs(sine), exponent), sine)
        let point = CGPoint(x: x, y: y)
        if step == 0 {
            path.move(to: point)
        } else {
            path.addLine(to: point)
        }
    }
    path.closeSubpath()
    return path
}

for output in outputs {
    let pixels = output.pixels
    let size = CGFloat(pixels)
    let bytesPerRow = pixels * 4
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: pixels,
        height: pixels,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        exit(70)
    }

    context.clear(CGRect(x: 0, y: 0, width: size, height: size))
    context.addPath(superellipsePath(size: size))
    context.clip()

    let inset = size * 0.04
    context.interpolationQuality = .high
    context.draw(
        sourceImage,
        in: CGRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
    )

    guard let renderedImage = context.makeImage() else {
        exit(70)
    }
    let outputURL = outputDirectory.appendingPathComponent(output.filename)
    guard let destination = CGImageDestinationCreateWithURL(
        outputURL as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        exit(73)
    }
    CGImageDestinationAddImage(destination, renderedImage, nil)
    guard CGImageDestinationFinalize(destination) else {
        exit(74)
    }
}
