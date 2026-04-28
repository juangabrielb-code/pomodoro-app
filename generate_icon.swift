#!/usr/bin/swift
import AppKit
import CoreGraphics
import Foundation

let outputDir = "Resources/Assets.xcassets/AppIcon.appiconset"
let baseSize: CGFloat = 1024

let greige = CGColor(red: 0.769, green: 0.725, blue: 0.659, alpha: 1)
let wine   = CGColor(red: 0.447, green: 0.184, blue: 0.216, alpha: 1)
let wineFaint = CGColor(red: 0.447, green: 0.184, blue: 0.216, alpha: 0.15)

func drawIcon(size: CGFloat) -> CGImage {
    let space = CGColorSpaceCreateDeviceRGB()
    let ctx   = CGContext(
        data: nil,
        width:  Int(size),
        height: Int(size),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: space,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!

    let center    = CGPoint(x: size / 2, y: size / 2)
    let ringPad   = size * 0.17
    let radius    = (size - ringPad * 2) / 2
    let lineWidth = size * 0.062

    // Background
    ctx.setFillColor(greige)
    ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

    // Faint ring track
    ctx.setStrokeColor(wineFaint)
    ctx.setLineWidth(lineWidth)
    ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    ctx.strokePath()

    // Progress ring — 75% filled, round caps, starting from top
    ctx.setStrokeColor(wine)
    ctx.setLineWidth(lineWidth)
    ctx.setLineCap(.round)
    let start: CGFloat = -.pi / 2
    let end: CGFloat   = start + .pi * 2 * 0.75
    ctx.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
    ctx.strokePath()

    // Center dot
    ctx.setFillColor(wine)
    let dotR = size * 0.055
    ctx.addArc(center: center, radius: dotR, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    ctx.fillPath()

    return ctx.makeImage()!
}

func savePNG(_ image: CGImage, size: Int, name: String) {
    let url  = URL(fileURLWithPath: "\(outputDir)/\(name)")
    let dest = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print("✓ \(name)")
}

let base = drawIcon(size: baseSize)

let sizes: [(Int, String)] = [
    (16,   "icon_16.png"),
    (32,   "icon_32.png"),
    (64,   "icon_64.png"),
    (128,  "icon_128.png"),
    (256,  "icon_256.png"),
    (512,  "icon_512.png"),
    (1024, "icon_1024.png"),
]

for (px, name) in sizes {
    if px == 1024 {
        savePNG(base, size: px, name: name)
    } else {
        let scaled = drawIcon(size: CGFloat(px))
        savePNG(scaled, size: px, name: name)
    }
}

print("Done — icons in \(outputDir)/")
