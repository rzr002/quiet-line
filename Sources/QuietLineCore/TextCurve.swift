import Foundation
import CoreFoundation

public enum CurveMode: String, Codable, Sendable { case line, text }

public enum TextCurveContent {
    public static func glyphs(from text: String) -> [String] {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ").map(String.init)
    }
    public static func decode(_ data: Data) throws -> String {
        if data.starts(with: [0xFF, 0xFE]) || data.starts(with: [0xFE, 0xFF]),
           let value = String(data: data, encoding: .utf16) { return value }
        if let value = String(data: data, encoding: .utf8) { return value }
        let encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
        if let value = String(data: data, encoding: encoding) { return value }
        throw TextCurveError.invalidEncoding
    }
}

public enum TextCurveError: Error, LocalizedError {
    case invalidEncoding
    public var errorDescription: String? { "无法读取这个 TXT，请使用 UTF-8、UTF-16 或 GB18030 编码。" }
}

public struct TextGlyphPlacement: Equatable, Sendable {
    public let index: Int
    public let x: Double
    public let y: Double
    public init(index: Int, x: Double, y: Double) { self.index = index; self.x = x; self.y = y }
}

public struct TextCurveFlow: Sendable {
    private let widths: [Double]
    private let prefix: [Double]
    public init(glyphWidths: [Double]) {
        widths = glyphWidths.map { $0.isFinite ? max(1, $0) : 1 }
        var accumulated = [0.0]
        accumulated.reserveCapacity(glyphWidths.count + 1)
        for width in widths { accumulated.append(accumulated.last! + width) }
        prefix = accumulated
    }
    public var cycleWidth: Double { prefix.last ?? 0 }
    public func placements(points: [CurvePoint], width: Double, height: Double, inset: Double, offset: Double) -> [TextGlyphPlacement] {
        guard !widths.isEmpty, cycleWidth > 0, points.count >= 2,
              width.isFinite, height.isFinite, width > 0, height > 0 else { return [] }
        let padding = min(max(0, inset), min(width, height) / 2)
        let span = width - padding * 2
        guard span > 0 else { return [] }
        let phase = offset.isFinite ? ((offset.truncatingRemainder(dividingBy: cycleWidth) + cycleWidth).truncatingRemainder(dividingBy: cycleWidth)) : 0
        // Binary search keeps a long novel's off-screen text out of each animation frame.
        var low = 0
        var high = widths.count
        while low < high {
            let middle = (low + high) / 2
            if prefix[middle + 1] <= phase { low = middle + 1 } else { high = middle }
        }
        var index = min(low, widths.count - 1)
        var x = padding - (phase - prefix[index])
        var result: [TextGlyphPlacement] = []
        while x < width - padding {
            let fraction = min(1, max(0, (x - padding) / span))
            var left = 0
            var right = points.count - 1
            while right - left > 1 {
                let middle = (left + right) / 2
                if points[middle].x <= fraction { left = middle } else { right = middle }
            }
            let distance = points[right].x - points[left].x
            let t = distance > 0 ? min(1, max(0, (fraction - points[left].x) / distance)) : 0
            let y = points[left].y + (points[right].y - points[left].y) * t
            result.append(TextGlyphPlacement(index: index, x: x, y: padding + y * (height - padding * 2)))
            x += widths[index]
            index = (index + 1) % widths.count
        }
        return result
    }
}
