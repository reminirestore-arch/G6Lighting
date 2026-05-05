// Generate AppIcon-1024.png. Run with:
//   swift assets/make-icon.swift
//
// Then ./assets/make-icns.sh wraps it into AppIcon.icns.
//
// Design: an RGB conic-gradient orb with a colored halo on a dark
// rounded-square background. References the in-app glowing preview but
// dialed up for icon prominence.

import AppKit
import CoreGraphics

let size: CGFloat = 1024
let canvas = NSImage(size: NSSize(width: size, height: size))
canvas.lockFocus()

guard let ctx = NSGraphicsContext.current?.cgContext else {
    fatalError("no graphics context")
}

let colorSpace = CGColorSpaceCreateDeviceRGB()

// 1. Rounded-square background, dark navy → black radial gradient.
let cornerRadius: CGFloat = size * 0.225  // matches macOS Sequoia squircle
let bgRect = CGRect(x: 0, y: 0, width: size, height: size)
let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)
ctx.saveGState()
bgPath.addClip()

let bgColors = [
    NSColor(srgbRed: 0.06, green: 0.07, blue: 0.13, alpha: 1).cgColor,
    NSColor(srgbRed: 0.0,  green: 0.0,  blue: 0.0,  alpha: 1).cgColor,
] as CFArray
let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0, 1])!
ctx.drawRadialGradient(
    bgGradient,
    startCenter: CGPoint(x: size/2, y: size/2), startRadius: 0,
    endCenter: CGPoint(x: size/2, y: size/2), endRadius: size * 0.75,
    options: []
)

// 2. Diffuse halo behind the orb — soft purple/blue glow.
let haloColors = [
    NSColor(srgbRed: 0.55, green: 0.25, blue: 1.0, alpha: 0.55).cgColor,
    NSColor(srgbRed: 0.0,  green: 0.45, blue: 1.0, alpha: 0.0).cgColor,
] as CFArray
let haloGradient = CGGradient(colorsSpace: colorSpace, colors: haloColors, locations: [0, 1])!
ctx.drawRadialGradient(
    haloGradient,
    startCenter: CGPoint(x: size/2, y: size/2), startRadius: size * 0.05,
    endCenter: CGPoint(x: size/2, y: size/2), endRadius: size * 0.45,
    options: []
)

// 3. Conic RGB orb — paint 360 thin wedges with hue rotation.
let orbCenter = CGPoint(x: size/2, y: size/2)
let orbRadius: CGFloat = size * 0.215
let segments = 720
for i in 0..<segments {
    let startDeg = CGFloat(i) * 360.0 / CGFloat(segments) - 90  // start at 12 o'clock
    let endDeg = startDeg + 360.0 / CGFloat(segments) + 0.5     // overlap to avoid gaps
    let hue = CGFloat(i) / CGFloat(segments)
    let color = NSColor(calibratedHue: hue, saturation: 0.95, brightness: 1.0, alpha: 1.0)
    color.setFill()
    let segPath = NSBezierPath()
    segPath.move(to: orbCenter)
    segPath.appendArc(
        withCenter: orbCenter,
        radius: orbRadius,
        startAngle: startDeg,
        endAngle: endDeg
    )
    segPath.close()
    segPath.fill()
}

// 4. White-hot inner glow (suggests an LED point source).
let coreColors = [
    NSColor(white: 1, alpha: 0.85).cgColor,
    NSColor(white: 1, alpha: 0.0).cgColor,
] as CFArray
let coreGradient = CGGradient(colorsSpace: colorSpace, colors: coreColors, locations: [0, 1])!
ctx.drawRadialGradient(
    coreGradient,
    startCenter: orbCenter, startRadius: 0,
    endCenter: orbCenter, endRadius: orbRadius * 0.55,
    options: []
)

// 5. Subtle thin ring around the orb to crisp the edge.
ctx.setStrokeColor(NSColor(white: 1, alpha: 0.18).cgColor)
ctx.setLineWidth(2.5)
ctx.strokeEllipse(in: CGRect(
    x: orbCenter.x - orbRadius,
    y: orbCenter.y - orbRadius,
    width: orbRadius * 2,
    height: orbRadius * 2
))

ctx.restoreGState()
canvas.unlockFocus()

// 6. Save as PNG.
guard let tiff = canvas.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:])
else {
    fatalError("PNG encoding failed")
}
let outURL = URL(fileURLWithPath: "assets/AppIcon-1024.png")
try png.write(to: outURL)
print("Saved: \(outURL.path) (\(png.count) bytes)")
