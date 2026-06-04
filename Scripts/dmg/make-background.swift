#!/usr/bin/env swift
//
// Generates the DMG window background for QuickCal releases.
//
//   swift Scripts/dmg/make-background.swift Scripts/dmg/dmg-background.png
//
// The layout is sized for a 600×400 create-dmg window (see .github/workflows/
// release.yml). It renders at 2× so the text stays crisp on Retina displays.
// The drop-arrow sits between the app icon (placed at 175,190 by create-dmg) and
// the Applications alias (425,190), and the amber callout spells out the one-time
// `xattr` step so the "damaged" Gatekeeper warning never catches anyone off guard.
//
import AppKit

let scale: CGFloat = 2
let W: CGFloat = 600, H: CGFloat = 400

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(W * scale), pixelsHigh: Int(H * scale),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
)!
rep.size = NSSize(width: W, height: H) // logical size → drawing happens at 2× pixels

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// AppKit's drawing origin is bottom-left; create-dmg's icon Y is measured from the
// top, so a Y of 190-from-top maps to (H - 190) here.
func text(_ s: String, _ font: NSFont, _ color: NSColor,
          _ rect: NSRect, _ align: NSTextAlignment = .center) {
    let p = NSMutableParagraphStyle()
    p.alignment = align
    p.lineBreakMode = .byClipping
    s.draw(in: rect, withAttributes: [.font: font, .foregroundColor: color, .paragraphStyle: p])
}

// Background: soft vertical gradient.
NSGradient(starting: NSColor(calibratedWhite: 0.985, alpha: 1),
           ending:   NSColor(calibratedWhite: 0.918, alpha: 1))!
    .draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -90)

// Header.
text("QuickCal", .systemFont(ofSize: 30, weight: .bold), .labelColor,
     NSRect(x: 0, y: H - 72, width: W, height: 42))
text("Drag QuickCal onto the Applications folder",
     .systemFont(ofSize: 13, weight: .regular), .secondaryLabelColor,
     NSRect(x: 0, y: H - 98, width: W, height: 20))

// Drop arrow between the two icons (both at Y 190 from top → 210 here).
let arrowY: CGFloat = H - 190
NSColor.tertiaryLabelColor.setStroke()
let shaft = NSBezierPath()
shaft.lineWidth = 4
shaft.lineCapStyle = .round
shaft.move(to: NSPoint(x: 250, y: arrowY))
shaft.line(to: NSPoint(x: 352, y: arrowY))
shaft.stroke()
let head = NSBezierPath()
head.lineWidth = 4
head.lineCapStyle = .round
head.lineJoinStyle = .round
head.move(to: NSPoint(x: 336, y: arrowY + 13))
head.line(to: NSPoint(x: 353, y: arrowY))
head.line(to: NSPoint(x: 336, y: arrowY - 13))
head.stroke()

// First-launch callout.
let box = NSRect(x: 38, y: 26, width: W - 76, height: 96)
let rounded = NSBezierPath(roundedRect: box, xRadius: 11, yRadius: 11)
NSColor(calibratedRed: 1.0, green: 0.972, blue: 0.875, alpha: 1).setFill()
rounded.fill()
NSColor(calibratedRed: 0.85, green: 0.66, blue: 0.13, alpha: 1).setStroke()
rounded.lineWidth = 1.5
rounded.stroke()

let pad = box.minX + 16
let innerW = box.width - 32
text("⚠️  First open says “damaged”? It isn’t — QuickCal just isn’t notarized.",
     .systemFont(ofSize: 12.5, weight: .semibold), .labelColor,
     NSRect(x: pad, y: box.maxY - 29, width: innerW, height: 18), .left)
text("Run this once in Terminal, then open QuickCal normally:",
     .systemFont(ofSize: 11, weight: .regular), .secondaryLabelColor,
     NSRect(x: pad, y: box.maxY - 49, width: innerW, height: 16), .left)
text("xattr -dr com.apple.quarantine /Applications/QuickCal.app",
     .monospacedSystemFont(ofSize: 12.5, weight: .medium),
     NSColor(calibratedRed: 0.18, green: 0.18, blue: 0.24, alpha: 1),
     NSRect(x: pad, y: box.minY + 13, width: innerW, height: 19), .left)

NSGraphicsContext.restoreGraphicsState()

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "dmg-background.png"
try! rep.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: out))
print("wrote \(out) — \(Int(W * scale))×\(Int(H * scale)) px")
