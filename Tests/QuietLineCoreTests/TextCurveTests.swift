import Foundation
import Testing
@testable import QuietLineCore

@Test func textCurveKeepsChineseAndEmojiAsReadableGraphemes() {
    #expect(TextCurveContent.glyphs(from: "春风\n  👨‍👩‍👧‍👦\t来") == ["春", "风", " ", "👨‍👩‍👧‍👦", " ", "来"])
    #expect(TextCurveContent.glyphs(from: "  \n  ").isEmpty)
}

@Test func shortSentenceLoopsWithoutAnEmptyGap() {
    let flow = TextCurveFlow(glyphWidths: [10, 10])
    let line = [CurvePoint(x: 0, y: 0), CurvePoint(x: 1, y: 1)]
    let items = flow.placements(points: line, width: 50, height: 100, inset: 0, offset: 5)
    #expect(flow.cycleWidth == 20)
    #expect(items.map(\.index) == [0, 1, 0, 1, 0, 1])
    #expect(items.map(\.x) == [-5, 5, 15, 25, 35, 45])
    #expect(items.dropFirst(2).first?.y == 30)
}

@Test func textMovementTracksPriceShapeAndWrapsAtExactCycle() {
    let flow = TextCurveFlow(glyphWidths: [10, 20, 10])
    let curve = [CurvePoint(x: 0, y: 0), CurvePoint(x: 0.5, y: 1), CurvePoint(x: 1, y: 0)]
    let before = flow.placements(points: curve, width: 100, height: 50, inset: 0, offset: 10)
    let after = flow.placements(points: curve, width: 100, height: 50, inset: 0, offset: 50)
    #expect(before == after)
    #expect(before.first?.index == 1)
    #expect(before.first?.x == 0)
    #expect(before.contains { $0.x == 40 && $0.y == 40 })
}

@Test func longTextStartsAtTheCurrentReadingPosition() {
    let flow = TextCurveFlow(glyphWidths: Array(repeating: 12, count: 100_000))
    let items = flow.placements(points: [.init(x: 0, y: 0.5), .init(x: 1, y: 0.5)], width: 360, height: 80, inset: 0, offset: 900_000)
    #expect(items.first?.index == 75_000)
    #expect(items.count == 30)
}

@Test func emptyTextAndMissingPricesDoNotInventACurve() {
    let line = [CurvePoint(x: 0, y: 0.5), CurvePoint(x: 1, y: 0.5)]
    #expect(TextCurveFlow(glyphWidths: []).placements(points: line, width: 100, height: 50, inset: 0, offset: 0).isEmpty)
    #expect(TextCurveFlow(glyphWidths: [0, .nan]).placements(points: [], width: 100, height: 50, inset: 0, offset: 0).isEmpty)
}

@Test func importsUTF8UTF16AndCommonChineseTXT() throws {
    #expect(try TextCurveContent.decode(Data("山河入梦".utf8)) == "山河入梦")
    #expect(try TextCurveContent.decode(Data([0xFF, 0xFE, 0x25, 0x66])) == "春")
    #expect(try TextCurveContent.decode(Data([0xD6, 0xD0, 0xCE, 0xC4])) == "中文")
}
