import Foundation

public struct FeedClient: Sendable {
    public init() {}
    // The futures website exposes the same public market-data schema.
    // Reuse the existing local proxy only for this app, without changing system settings.
    private static let futuresSession: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        let port = Int(ProcessInfo.processInfo.environment["QUIETLINE_PROXY_PORT"] ?? "7897") ?? 7897
        config.connectionProxyDictionary = ["HTTPEnable": 1, "HTTPProxy": "127.0.0.1", "HTTPPort": port,
                                           "HTTPSEnable": 1, "HTTPSProxy": "127.0.0.1", "HTTPSPort": port]
        return URLSession(configuration: config)
    }()
    public func fetch(_ instrument: Instrument, range: HistoryRange = .hour) async throws -> PriceSeries {
        let data = try await request("klines?symbol=\(instrument.symbol)&interval=\(range.interval)&limit=\(range.limit)", venue: instrument.venue ?? .spot)
        let decoded = try SeriesDecoder.binance(data)
        let label = instrument.venue == .perpetual ? "Binance 永续合约 · 每 2 秒更新" : "Binance 现货 · 每 2 秒更新"
        return PriceSeries(points: decoded.points, source: label)
    }
    public func latest(_ instrument: Instrument) async throws -> Observation {
        let data = try await request("aggTrades?symbol=\(instrument.symbol)&limit=1", venue: instrument.venue ?? .spot)
        return try SeriesDecoder.binanceTrade(data)
    }
    private func request(_ path: String, venue: Venue) async throws -> Data {
        let base = venue == .perpetual ? "https://www.binance.com/fapi/v1/" : "https://data-api.binance.vision/api/v3/"
        guard let url = URL(string: base + path) else { throw FeedError.invalidSymbol }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 8)
        request.setValue("QuietLine/0.3", forHTTPHeaderField: "User-Agent")
        let data: Data
        let response: URLResponse
        if venue == .perpetual {
            do { (data, response) = try await Self.futuresSession.data(for: request) }
            catch { (data, response) = try await URLSession.shared.data(for: request) }
        } else { (data, response) = try await URLSession.shared.data(for: request) }
        guard let http = response as? HTTPURLResponse else { throw FeedError.invalidResponse }
        if http.statusCode == 451 { throw FeedError.regionRestricted }
        guard (200..<300).contains(http.statusCode) else { throw FeedError.invalidResponse }
        try Task.checkCancellation()
        return data
    }
}
