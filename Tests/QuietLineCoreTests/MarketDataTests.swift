import Foundation
import Testing
@testable import QuietLineCore

@Test func acceptsCryptoSymbolsAndRejectsMalformedInput() throws {
    #expect(try Instrument.custom("btc/usdt").symbol == "BTCUSDT")
    #expect(try Instrument.custom(" ETH ").symbol == "ETHUSDT")
    #expect(try Instrument.custom("SOL-USDT").symbol == "SOLUSDT")
    for input in ["", "../?bad", "BTC & ETH"] {
        #expect(throws: FeedError.self) { try Instrument.custom(input) }
    }
}

@Test func decodesCryptoClosePricesAndSortsByTime() throws {
    let fixture = #"[[2000,"10","15","9","12.5"],[1000,"11","14","10","11.5"],[3000,"1","2","0","0"]]"#
    let series = try SeriesDecoder.binance(Data(fixture.utf8))
    #expect(series.points.map(\.price) == [11.5, 12.5])
    #expect(series.points.first?.time == Date(timeIntervalSince1970: 1))
}

@Test func neverTurnsAPIErrorsIntoPrices() {
    for input in ["<html>blocked</html>", #"{"code":-1121,"msg":"Invalid symbol"}"#, "[]"] {
        #expect(throws: FeedError.self) { try SeriesDecoder.binance(Data(input.utf8)) }
        #expect(throws: FeedError.self) { try SeriesDecoder.binanceTrade(Data(input.utf8)) }
    }
}

@Test func normalizesRealShapeWithoutAddingPoints() {
    let points = CurveGeometry.normalize([100, 103, 99, 101])
    #expect(points.count == 4)
    #expect(points.first?.x == 0)
    #expect(points.last?.x == 1)
    #expect(points.map(\.y) == [0.25, 1, 0, 0.5])
}

@Test func flatAndInsufficientSeriesStayHonest() {
    #expect(CurveGeometry.normalize([42, 42, 42]).map(\.y) == [0.5, 0.5, 0.5])
    #expect(CurveGeometry.normalize([]).isEmpty)
    #expect(CurveGeometry.normalize([42]).isEmpty)
    #expect(CurveGeometry.normalize([Double.nan, Double.infinity]).isEmpty)
}

@Test func onlyFreshConnectedCurvesPulse() {
    let now = Date(timeIntervalSince1970: 1794380400)
    #expect(CurveActivity.isUpdating(lastPointAt: now.addingTimeInterval(-2), receivedAt: now, now: now))
    #expect(!CurveActivity.isUpdating(lastPointAt: now.addingTimeInterval(-180), receivedAt: now, now: now))
    #expect(!CurveActivity.isUpdating(lastPointAt: now, receivedAt: now.addingTimeInterval(-20), now: now))
    #expect(!CurveActivity.isUpdating(lastPointAt: nil, receivedAt: now, now: now))
}
