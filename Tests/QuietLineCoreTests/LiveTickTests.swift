import Foundation
import Testing
@testable import QuietLineCore

@Test func decodesActualBinanceTradeTimeAndPrice() throws {
    let data = Data(#"[{"a":123,"p":"75001.25","q":"0.1","T":1794380401234}]"#.utf8)
    let tick = try SeriesDecoder.binanceTrade(data)
    #expect(tick.price == 75001.25)
    #expect(tick.time == Date(timeIntervalSince1970: 1794380401.234))
}

@Test func liveTradeUpdatesLastMinuteInsteadOfInventingPoints() {
    let series = PriceSeries(points: [.init(time: Date(timeIntervalSince1970: 60), price: 100), .init(time: Date(timeIntervalSince1970: 120), price: 101)], source: "Binance")
    let updated = series.applying(.init(time: Date(timeIntervalSince1970: 145), price: 102), bucketSeconds: 60, limit: 60)
    #expect(updated.points.map(\.price) == [100, 102])
    #expect(updated.points.last?.time == Date(timeIntervalSince1970: 145))
}

@Test func newMinuteAdvancesWindowAndOldTradesCannotRewindIt() {
    let series = PriceSeries(points: [.init(time: Date(timeIntervalSince1970: 60), price: 100), .init(time: Date(timeIntervalSince1970: 120), price: 101)], source: "Binance")
    let updated = series.applying(.init(time: Date(timeIntervalSince1970: 185), price: 103), bucketSeconds: 60, limit: 2)
    #expect(updated.points.map(\.price) == [101, 103])
    let old = updated.applying(.init(time: Date(timeIntervalSince1970: 100), price: 90), bucketSeconds: 60, limit: 2)
    #expect(old.points == updated.points)
}
