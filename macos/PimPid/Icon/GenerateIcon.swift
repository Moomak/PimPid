#!/usr/bin/env swift
import AppKit
import Foundation

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))

image.lockFocus()

let rect = NSRect(x: 0, y: 0, width: size, height: size)
let ctx = NSGraphicsContext.current!.cgContext

// พื้นหลัง gradient (เทาเข้ม → เทาอ่อน)
let colors = [NSColor(white: 0.22, alpha: 1).cgColor, NSColor(white: 0.35, alpha: 1).cgColor]
let colorSpace = CGColorSpaceCreateDeviceGray()
let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])

// รูปคีย์บอร์ด (rounded rect ใหญ่)
let kbMargin: CGFloat = 120
let kbRect = rect.insetBy(dx: kbMargin, dy: kbMargin)
let kbPath = NSBezierPath(roundedRect: kbRect, xRadius: 80, yRadius: 80)
NSColor(white: 0.15, alpha: 1).setFill()
kbPath.fill()
NSColor(white: 0.5, alpha: 0.6).setStroke()
kbPath.lineWidth = 12
kbPath.stroke()

// แถวคีย์ (สี่เหลี่ยมเล็ก ๆ หลายอัน)
let keyColor = NSColor(white: 0.28, alpha: 1)
let keyHighlight = NSColor(white: 0.45, alpha: 1)
let rows: [(yRatio: CGFloat, count: Int)] = [(0.72, 12), (0.52, 11), (0.32, 10)]
let keyW: CGFloat = (kbRect.width - 80) / 12
let keyH: CGFloat = 70
let keyRadius: CGFloat = 12

for (yRatio, count) in rows {
    let y = kbRect.minY + kbRect.height * yRatio
    let totalW = keyW * CGFloat(count) + 8 * CGFloat(count - 1)
    let startX = kbRect.minX + (kbRect.width - totalW) / 2 + keyW / 2 + 4
    for i in 0..<count {
        let x = startX + CGFloat(i) * (keyW + 8) - keyW / 2
        let keyRect = NSRect(x: x, y: y, width: keyW, height: keyH)
        let keyPath = NSBezierPath(roundedRect: keyRect, xRadius: keyRadius, yRadius: keyRadius)
        keyColor.setFill()
        keyPath.fill()
        keyHighlight.setStroke()
        keyPath.lineWidth = 2
        keyPath.stroke()
    }
}

// สัญลักษณ์สลับภาษา (ลูกศรซ้าย-ขวา ↔) ตรงกลาง
let centerX = size / 2 as CGFloat
let centerY = size / 2 as CGFloat
let arrowRadius: CGFloat = 140
let arrowColor = NSColor(white: 0.95, alpha: 1)
let circleBg = NSColor(red: 0.25, green: 0.45, blue: 0.75, alpha: 1)

// วงกลมหลังลูกศร
let circleRect = NSRect(x: centerX - arrowRadius - 40, y: centerY - arrowRadius - 40,
                        width: (arrowRadius + 40) * 2, height: (arrowRadius + 40) * 2)
let circlePath = NSBezierPath(ovalIn: circleRect)
circleBg.setFill()
circlePath.fill()
NSColor(white: 0.9, alpha: 0.5).setStroke()
circlePath.lineWidth = 8
circlePath.stroke()

// วาดลูกศรซ้าย-ขวา (↔) ด้วยเส้นและหัวลูกศร
let arrowY = centerY
let arrowW: CGFloat = 100
let arrowHead: CGFloat = 28
let leftX = centerX - arrowW
let rightX = centerX + arrowW

let arrowPath = NSBezierPath()
arrowPath.lineWidth = 22
arrowPath.lineCapStyle = .round
arrowPath.lineJoinStyle = .round
arrowPath.move(to: CGPoint(x: leftX, y: arrowY))
arrowPath.line(to: CGPoint(x: rightX, y: arrowY))
arrowColor.setStroke()
arrowPath.stroke()

// หัวลูกศรซ้าย (ชี้ซ้าย)
let leftArrow = NSBezierPath()
leftArrow.move(to: CGPoint(x: leftX + arrowHead, y: arrowY - 35.0))
leftArrow.line(to: CGPoint(x: leftX - 15.0, y: arrowY))
leftArrow.line(to: CGPoint(x: leftX + arrowHead, y: arrowY + 35.0))
leftArrow.close()
arrowColor.setFill()
leftArrow.fill()

// หัวลูกศรขวา (ชี้ขวา)
let rightArrow = NSBezierPath()
rightArrow.move(to: CGPoint(x: rightX - arrowHead, y: arrowY - 35.0))
rightArrow.line(to: CGPoint(x: rightX + 15.0, y: arrowY))
rightArrow.line(to: CGPoint(x: rightX - arrowHead, y: arrowY + 35.0))
rightArrow.close()
arrowColor.setFill()
rightArrow.fill()

image.unlockFocus()

// บันทึก PNG
guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Failed to create PNG\n", stderr)
    exit(1)
}

let outDir = ProcessInfo.processInfo.environment["ICON_OUT"] ?? FileManager.default.currentDirectoryPath
let outPath = (outDir as NSString).appendingPathComponent("icon_1024.png")
try? pngData.write(to: URL(fileURLWithPath: outPath))
print(outPath)
