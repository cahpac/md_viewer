import Foundation
import CoreGraphics
import ImageIO

struct RGBA {
    let r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat
}

func color(_ hex: UInt32, _ alpha: CGFloat = 1.0) -> CGColor {
    let r = CGFloat((hex >> 16) & 0xFF) / 255.0
    let g = CGFloat((hex >> 8) & 0xFF) / 255.0
    let b = CGFloat(hex & 0xFF) / 255.0
    return CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, components: [r, g, b, alpha])!
}

func drawRoundedRect(ctx: CGContext, rect: CGRect, radius: CGFloat, fill: CGColor? = nil) {
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.addPath(path)
    if let fill = fill {
        ctx.setFillColor(fill)
        ctx.drawPath(using: .fill)
    } else {
        ctx.drawPath(using: .fill)
    }
}

func drawLinearGradient(ctx: CGContext, rect: CGRect, colors: [CGColor], start: CGPoint, end: CGPoint) {
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0])!
    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: rect.height * 0.172, cornerHeight: rect.height * 0.172, transform: nil))
    ctx.clip()
    ctx.drawLinearGradient(gradient, start: start, end: end, options: [])
    ctx.restoreGState()
}

func drawLogo(in ctx: CGContext, size px: Int) {
    let s = CGFloat(px)
    ctx.setFillColor(color(0xFFFFFF))
    ctx.fill(CGRect(x: 0, y: 0, width: s, height: s))

    // Background rounded square with blue gradient
    let inset: CGFloat = s * 0.0625 // 64 on 1024
    let bgRect = CGRect(x: inset, y: inset, width: s - inset*2, height: s - inset*2)
    let radius = s * 0.172 // ~176 on 1024
    let path = CGPath(roundedRect: bgRect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let grad = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: [color(0x0A84FF), color(0x2563EB)] as CFArray, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: bgRect.minX, y: bgRect.minY), end: CGPoint(x: bgRect.maxX, y: bgRect.maxY), options: [])
    ctx.restoreGState()

    // Document card
    let docRect = CGRect(
        x: s * 0.25,    // 256
        y: s * 0.203125,// 208
        width: s * 0.5, // 512
        height: s * 0.609375 // 624
    )
    drawRoundedRect(ctx: ctx, rect: docRect, radius: s * 0.039, fill: color(0xFFFFFF))

    // Top accent bar
    let topBar = CGRect(x: docRect.minX, y: docRect.minY, width: docRect.width, height: s * 0.0703125) // 72
    drawRoundedRect(ctx: ctx, rect: topBar, radius: s * 0.039, fill: color(0xEEF6FF))

    // "#" symbol using 4 bars
    func drawBar(_ r: CGRect) {
        drawRoundedRect(ctx: ctx, rect: r, radius: min(r.width, r.height) * 0.3, fill: color(0x0F172A))
    }
    let hashX = s * 0.293 // ~300
    let hashY = s * 0.351 // ~360
    let barW = s * 0.014 // thickness
    let barH = s * 0.12
    // two verticals
    drawBar(CGRect(x: hashX, y: hashY - barH*0.5, width: barW, height: barH))
    drawBar(CGRect(x: hashX + barW*2.0, y: hashY - barH*0.5, width: barW, height: barH))
    // two horizontals
    drawBar(CGRect(x: hashX - barH*0.2, y: hashY - barW*1.2, width: barH, height: barW))
    drawBar(CGRect(x: hashX - barH*0.15, y: hashY + barW*1.2, width: barH, height: barW))

    // Content lines
    func line(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ col: UInt32) {
        drawRoundedRect(ctx: ctx, rect: CGRect(x: x, y: y, width: w, height: h), radius: h/2, fill: color(col))
    }
    let lineX = s * 0.293
    let lineY0 = s * 0.381 // 390
    let lh = s * 0.0176     // 18
    line(lineX, lineY0, s * 0.375, lh, 0xE5E7EB)
    line(lineX, lineY0 + lh*2.0, s * 0.343, lh, 0xE5E7EB)
    line(lineX, lineY0 + lh*4.0, s * 0.359, lh, 0xE5E7EB)

    let paraY = lineY0 + lh*7.0
    line(lineX, paraY, s * 0.395, lh, 0xE5E7EB)
    line(lineX, paraY + lh*2.0, s * 0.332, lh, 0xE5E7EB)
    line(lineX, paraY + lh*4.0, s * 0.367, lh, 0xE5E7EB)

    // Code block bar
    drawRoundedRect(ctx: ctx, rect: CGRect(x: lineX, y: paraY + lh*7.0, width: s * 0.234, height: lh*1.55), radius: lh*0.775, fill: color(0xF3F4F6))

    // Brackets
    ctx.setFillColor(color(0xD9E6FF))
    // Left bracket
    let lbx = s * 0.195
    let lby = s * 0.343
    let lbw = s * 0.07
    let lbh = s * 0.312
    let lbr = CGMutablePath()
    lbr.move(to: CGPoint(x: lbx, y: lby + lbh))
    lbr.addLine(to: CGPoint(x: lbx, y: lby + lbh - s*0.02))
    lbr.addLine(to: CGPoint(x: lbx + lbw*0.6, y: lby + lbh - s*0.02))
    lbr.addLine(to: CGPoint(x: lbx + lbw*0.6, y: lby + s*0.02))
    lbr.addLine(to: CGPoint(x: lbx, y: lby + s*0.02))
    lbr.addLine(to: CGPoint(x: lbx, y: lby))
    lbr.addLine(to: CGPoint(x: lbx + lbw, y: lby))
    lbr.addLine(to: CGPoint(x: lbx + lbw, y: lby + lbh))
    lbr.closeSubpath()
    ctx.addPath(lbr)
    ctx.fillPath()

    // Right bracket
    let rbx = s * 0.805
    let rby = lby
    let rbw = lbw
    let rbh = lbh
    let rbr = CGMutablePath()
    rbr.move(to: CGPoint(x: rbx, y: rby + lbh))
    rbr.addLine(to: CGPoint(x: rbx, y: rby + lbh - s*0.02))
    rbr.addLine(to: CGPoint(x: rbx - rbw*0.6, y: rby + lbh - s*0.02))
    rbr.addLine(to: CGPoint(x: rbx - rbw*0.6, y: rby + s*0.02))
    rbr.addLine(to: CGPoint(x: rbx, y: rby + s*0.02))
    rbr.addLine(to: CGPoint(x: rbx, y: rby))
    rbr.addLine(to: CGPoint(x: rbx - rbw, y: rby))
    rbr.addLine(to: CGPoint(x: rbx - rbw, y: rby + rbh))
    rbr.closeSubpath()
    ctx.addPath(rbr)
    ctx.fillPath()

    // AI spark (simple 8-point star)
    let scx = s * 0.672
    let scy = s * 0.172
    let r1 = s * 0.028
    let r2 = s * 0.014
    let star = CGMutablePath()
    let points = 8
    for i in 0..<(points*2) {
        let angle = (Double(i) * (Double.pi / Double(points))) + Double.pi/8.0
        let r = (i % 2 == 0) ? Double(r1) : Double(r2)
        let x = Double(scx) + cos(angle) * r
        let y = Double(scy) + sin(angle) * r
        if i == 0 { star.move(to: CGPoint(x: x, y: y)) } else { star.addLine(to: CGPoint(x: x, y: y)) }
    }
    star.closeSubpath()
    ctx.saveGState()
    ctx.addPath(star)
    ctx.clip()
    let sparkGrad = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: [color(0x22D3EE), color(0x14B8A6)] as CFArray, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(sparkGrad, start: CGPoint(x: scx - r1, y: scy - r1), end: CGPoint(x: scx + r1, y: scy + r1), options: [])
    ctx.restoreGState()
    ctx.setFillColor(color(0xFFFFFF, 0.9))
    ctx.fillEllipse(in: CGRect(x: scx - s*0.006, y: scy - s*0.006, width: s*0.012, height: s*0.012))
}

func pngData(from ctx: CGContext) -> Data? {
    guard let image = ctx.makeImage() else { return nil }
    let mutableData = CFDataCreateMutable(nil, 0)!
    guard let dest = CGImageDestinationCreateWithData(mutableData, kUTTypePNG, 1, nil) else { return nil }
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { return nil }
    return mutableData as Data
}

func makeContext(size px: Int) -> CGContext? {
    let width = px
    let height = px
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    return CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
}

struct Entry { let idiom: String; let size: String; let scale: String; let filename: String; let pixels: Int }

let appIconPath = "md_viewer_xcode/md_viewer_xcode/Assets.xcassets/AppIcon.appiconset"
let entries: [Entry] = [
    .init(idiom: "mac", size: "16x16", scale: "1x", filename: "icon_16.png", pixels: 16),
    .init(idiom: "mac", size: "16x16", scale: "2x", filename: "icon_16@2x.png", pixels: 32),
    .init(idiom: "mac", size: "32x32", scale: "1x", filename: "icon_32.png", pixels: 32),
    .init(idiom: "mac", size: "32x32", scale: "2x", filename: "icon_32@2x.png", pixels: 64),
    .init(idiom: "mac", size: "128x128", scale: "1x", filename: "icon_128.png", pixels: 128),
    .init(idiom: "mac", size: "128x128", scale: "2x", filename: "icon_128@2x.png", pixels: 256),
    .init(idiom: "mac", size: "256x256", scale: "1x", filename: "icon_256.png", pixels: 256),
    .init(idiom: "mac", size: "256x256", scale: "2x", filename: "icon_256@2x.png", pixels: 512),
    .init(idiom: "mac", size: "512x512", scale: "1x", filename: "icon_512.png", pixels: 512),
    .init(idiom: "mac", size: "512x512", scale: "2x", filename: "icon_512@2x.png", pixels: 1024),
]

do {
    let fm = FileManager.default
    guard fm.fileExists(atPath: appIconPath) else {
        fputs("AppIcon.appiconset path not found: \(appIconPath)\n", stderr)
        exit(1)
    }

    // Generate images
    for e in entries {
        guard let ctx = makeContext(size: e.pixels) else { fatalError("Context failed") }
        ctx.interpolationQuality = .high
        ctx.translateBy(x: 0, y: 0)
        drawLogo(in: ctx, size: e.pixels)
        guard let data = pngData(from: ctx) else { fatalError("PNG encode failed") }
        let outPath = appIconPath + "/" + e.filename
        try data.write(to: URL(fileURLWithPath: outPath))
        print("Wrote \(outPath)")
    }

    // Write Contents.json
    let imagesArray: [[String: Any]] = entries.map { e in
        [
            "idiom": e.idiom,
            "size": e.size,
            "scale": e.scale,
            "filename": e.filename
        ]
    }
    let info: [String: Any] = ["author": "codex", "version": 1]
    let json: [String: Any] = ["images": imagesArray, "info": info]
    let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: URL(fileURLWithPath: appIconPath + "/Contents.json"))
    print("Updated Contents.json")
} catch {
    fputs("Error: \(error)\n", stderr)
    exit(1)
}

