#!/usr/bin/swift
import CoreGraphics
import Foundation
import ImageIO

// ── Colors ────────────────────────────────────────────────────────────────────
let greige   = CGColor(red: 0.769, green: 0.725, blue: 0.659, alpha: 1.0) // #C4B9A8
let wineDark = CGColor(red: 0.447, green: 0.184, blue: 0.216, alpha: 1.0) // #722F37
let wineMid  = CGColor(red: 0.580, green: 0.360, blue: 0.380, alpha: 1.0) // #947080

// ── Draw ──────────────────────────────────────────────────────────────────────
// Top-down cross-section of a tomato: outer skin ring, inner flesh,
// 6 radial chamber dividers, one seed per chamber.
func drawTomato(size: CGFloat) -> CGImage {
    let ctx = CGContext(
        data:             nil,
        width:            Int(size),
        height:           Int(size),
        bitsPerComponent: 8,
        bytesPerRow:      0,
        space:            CGColorSpaceCreateDeviceRGB(),
        bitmapInfo:       CGImageAlphaInfo.premultipliedLast.rawValue
    )!

    let cx      = size / 2
    let cy      = size / 2
    let outerR  = size * 0.435   // outer edge (skin)
    let innerR  = size * 0.360   // inner flesh (skin ring is ~7.5% wide)
    let coreR   = size * 0.058   // central placenta dot
    let lineW   = size * 0.024   // chamber wall thickness
    let seedW   = size * 0.042   // seed long axis
    let seedH   = size * 0.021   // seed short axis
    let seedD   = innerR * 0.60  // distance from center to seed
    let nSegs   = 6
    let tau     = 2.0 * CGFloat.pi

    // Background
    ctx.setFillColor(greige)
    ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

    // Outer skin — wineDark full circle
    ctx.setFillColor(wineDark)
    ctx.addEllipse(in: CGRect(x: cx - outerR, y: cy - outerR,
                               width: outerR * 2, height: outerR * 2))
    ctx.fillPath()

    // Inner flesh — wineMid circle
    ctx.setFillColor(wineMid)
    ctx.addEllipse(in: CGRect(x: cx - innerR, y: cy - innerR,
                               width: innerR * 2, height: innerR * 2))
    ctx.fillPath()

    // Chamber dividers — wineDark radial lines
    ctx.setStrokeColor(wineDark)
    ctx.setLineWidth(lineW)
    ctx.setLineCap(.round)
    for i in 0..<nSegs {
        let angle = tau * CGFloat(i) / CGFloat(nSegs)
        ctx.move(to: CGPoint(x: cx, y: cy))
        ctx.addLine(to: CGPoint(x: cx + cos(angle) * innerR,
                                y: cy + sin(angle) * innerR))
    }
    ctx.strokePath()

    // Central placenta — wineDark dot
    ctx.setFillColor(wineDark)
    ctx.addEllipse(in: CGRect(x: cx - coreR, y: cy - coreR,
                               width: coreR * 2, height: coreR * 2))
    ctx.fillPath()

    // Seeds — greige ovals, centered in each chamber, rotated radially
    ctx.setFillColor(greige)
    for i in 0..<nSegs {
        let angle = tau * CGFloat(i) / CGFloat(nSegs)
                  + tau / CGFloat(nSegs * 2) // shift to chamber mid-angle
        let sx = cx + cos(angle) * seedD
        let sy = cy + sin(angle) * seedD
        ctx.saveGState()
        ctx.translateBy(x: sx, y: sy)
        ctx.rotate(by: angle)
        ctx.addEllipse(in: CGRect(x: -seedW / 2, y: -seedH / 2,
                                   width: seedW, height: seedH))
        ctx.fillPath()
        ctx.restoreGState()
    }

    return ctx.makeImage()!
}

// ── Save ──────────────────────────────────────────────────────────────────────
func savePNG(_ image: CGImage, to path: String) {
    let url = URL(fileURLWithPath: path)
    try? FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print("✓  \(path)")
}

// ── Run ───────────────────────────────────────────────────────────────────────
let icon = drawTomato(size: 1024)
savePNG(icon, to: "flutter/assets/icon/icon.png")
print("\nDone. Next steps:")
print("  cd flutter && flutter pub get && dart run flutter_launcher_icons")
