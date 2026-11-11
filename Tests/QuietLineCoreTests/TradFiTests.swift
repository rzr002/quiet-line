import Testing
@testable import QuietLineCore

@Test func nasdaqInputSelectsActualBinancePerpetualInsteadOfStockOrSpot() throws {
    let qqq = try Instrument.custom("QQQ")
    #expect(qqq.symbol == "QQQUSDT")
    #expect(qqq.venue == .perpetual)
    #expect(Instrument.presets.contains { $0.symbol == "QQQUSDT" && $0.venue == .perpetual })
}

@Test func stockPerpetualsAndCryptoSpotStayDistinct() throws {
    #expect(try Instrument.custom("NVDAUSDT").venue == .perpetual)
    #expect(try Instrument.custom("BTC").venue == .spot)
}
