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
    public func placements(points: [CurvePoint], width: Double, height: Double, inset: Double, offset: Double, alongCurve: Bool = false) -> [TextGlyphPlacement] {
        guard !widths.isEmpty, cycleWidth > 0, points.count >= 2,
              width.isFinite, height.isFinite, width > 0, height > 0 else { return [] }
        let padding = min(max(0, inset), min(width, height) / 2)
        let span = width - padding * 2
        guard span > 0 else { return [] }
        let path = points.map { CurvePoint(x: padding + $0.x * span, y: padding + $0.y * (height - padding * 2)) }
        var distances = points.map { $0.x * span }
        if alongCurve {
            distances = [0]
            for index in 1..<path.count {
                let previous = path[index - 1]
                let next = path[index]
                distances.append(distances.last! + hypot(next.x - previous.x, next.y - previous.y))
            }
        }
        let pathLength = alongCurve ? distances.last! : span
        guard pathLength > 0 else { return [] }
        let phase = offset.isFinite ? ((offset.truncatingRemainder(dividingBy: cycleWidth) + cycleWidth).truncatingRemainder(dividingBy: cycleWidth)) : 0
        // Binary search keeps a long novel's off-screen text out of each animation frame.
        var low = 0
        var high = widths.count
        while low < high {
            let middle = (low + high) / 2
            if prefix[middle + 1] <= phase { low = middle + 1 } else { high = middle }
        }
        var index = min(low, widths.count - 1)
        var position = -(phase - prefix[index])
        var result: [TextGlyphPlacement] = []
        while position < pathLength {
            var left = 0
            var right = points.count - 1
            while right - left > 1 {
                let middle = (left + right) / 2
                if distances[middle] <= position { left = middle } else { right = middle }
            }
            let distance = distances[right] - distances[left]
            let progress = distance > 0 ? (position - distances[left]) / distance : 0
            let t = alongCurve ? progress : min(1, max(0, progress))
            let x = alongCurve ? path[left].x + (path[right].x - path[left].x) * t : padding + position
            let y = path[left].y + (path[right].y - path[left].y) * t
            result.append(TextGlyphPlacement(index: index, x: x, y: y))
            position += widths[index]
            index = (index + 1) % widths.count
        }
        return result
    }
}
