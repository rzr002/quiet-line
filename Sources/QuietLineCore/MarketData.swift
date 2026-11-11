import Foundation

public enum Venue: String, Codable, CaseIterable, Sendable {
    case spot, perpetual
    public var title: String { self == .spot ? "加密货币 · 币安现货" : "纳指 / 美股 · 币安永续" }
}

public struct Instrument: Identifiable, Codable, Equatable, Sendable {
    public var id: String { "\((venue ?? .spot).rawValue):\(symbol)" }
    public let name: String
    public let symbol: String
    public let venue: Venue?
    public init(name: String, symbol: String, venue: Venue = .spot) { self.name = name; self.symbol = symbol; self.venue = venue }

    public static func custom(_ input: String, venue: Venue? = nil) throws -> Instrument {
        let clean = input.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            .replacingOccurrences(of: "/", with: "").replacingOccurrences(of: "-", with: "")
        guard clean.range(of: "^[A-Z0-9]{2,20}$", options: .regularExpression) != nil else { throw FeedError.invalidSymbol }
        let symbol = clean.hasSuffix("USDT") ? clean : clean + "USDT"
        if let known = presets.first(where: { $0.symbol == symbol && (venue == nil || $0.venue == venue) }) { return known }
        return Instrument(name: String(symbol.dropLast(4)), symbol: symbol, venue: venue ?? .spot)
    }

    public static let presets: [Instrument] = [
        .init(name: "纳指 100 · QQQ", symbol: "QQQUSDT", venue: .perpetual),
        .init(name: "标普 500 · SPY", symbol: "SPYUSDT", venue: .perpetual),
        .init(name: "英伟达 · NVDA", symbol: "NVDAUSDT", venue: .perpetual),
        .init(name: "苹果 · AAPL", symbol: "AAPLUSDT", venue: .perpetual),
        .init(name: "特斯拉 · TSLA", symbol: "TSLAUSDT", venue: .perpetual),
        .init(name: "微软 · MSFT", symbol: "MSFTUSDT", venue: .perpetual),
        .init(name: "谷歌 · GOOGL", symbol: "GOOGLUSDT", venue: .perpetual),
        .init(name: "亚马逊 · AMZN", symbol: "AMZNUSDT", venue: .perpetual),
        .init(name: "Meta", symbol: "METAUSDT", venue: .perpetual),
        .init(name: "Bitcoin", symbol: "BTCUSDT"), .init(name: "Ethereum", symbol: "ETHUSDT"),
        .init(name: "Solana", symbol: "SOLUSDT"), .init(name: "BNB", symbol: "BNBUSDT"),
        .init(name: "XRP", symbol: "XRPUSDT"), .init(name: "Dogecoin", symbol: "DOGEUSDT"),
        .init(name: "Cardano", symbol: "ADAUSDT"), .init(name: "Avalanche", symbol: "AVAXUSDT")
    ]
}

public enum HistoryRange: Int, CaseIterable, Codable, Sendable {
    case hour = 60, fourHours = 240, day = 1440
    public var title: String { switch self { case .hour: "1 小时"; case .fourHours: "4 小时"; case .day: "24 小时" } }
    public var interval: String { self == .day ? "5m" : "1m" }
    public var limit: Int { self == .day ? 288 : rawValue }
    public var bucketSeconds: Double { self == .day ? 300 : 60 }
}

public struct Observation: Equatable, Sendable {
    public let time: Date
    public let price: Double
    public init(time: Date, price: Double) { self.time = time; self.price = price }
}

public struct PriceSeries: Sendable {
    public let points: [Observation]
    public let source: String
    public init(points: [Observation], source: String) { self.points = points; self.source = source }
    public func applying(_ tick: Observation, bucketSeconds: Double, limit: Int) -> PriceSeries {
        guard tick.price.isFinite, tick.price > 0, bucketSeconds > 0, limit >= 2,
              let last = points.last, tick.time >= last.time else { return self }
        var next = points
        if floor(tick.time.timeIntervalSince1970 / bucketSeconds) == floor(last.time.timeIntervalSince1970 / bucketSeconds) {
            next[next.count - 1] = tick
        } else { next.append(tick) }
        return PriceSeries(points: Array(next.suffix(limit)), source: source)
    }
}

public enum FeedError: Error, LocalizedError {
    case invalidSymbol, noData, invalidResponse, regionRestricted
    public var errorDescription: String? {
        switch self {
        case .invalidSymbol: "请输入 Binance USDT 交易对，例如 BTC、ETH 或 SOLUSDT。"
        case .noData: "暂时没有足够的行情，请检查交易对。"
        case .invalidResponse: "Binance 行情暂时不可用，稍后自动重试。"
        case .regionRestricted: "当前网络无法读取该币安合约行情（451）。"
        }
    }
}

public enum SeriesDecoder {
    public static func binance(_ data: Data) throws -> PriceSeries {
        guard let rows = try? JSONSerialization.jsonObject(with: data) as? [[Any]] else { throw FeedError.invalidResponse }
        let points = rows.compactMap { row -> Observation? in
            guard row.count >= 5, let millis = row[0] as? Double, millis.isFinite,
                  let text = row[4] as? String, let price = Double(text), price.isFinite, price > 0 else { return nil }
            return Observation(time: Date(timeIntervalSince1970: millis / 1000), price: price)
        }.sorted { $0.time < $1.time }
        guard points.count >= 2 else { throw FeedError.noData }
        return PriceSeries(points: points, source: "Binance · 最新成交每 2 秒更新")
    }
    public static func binanceTrade(_ data: Data) throws -> Observation {
        guard let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let row = rows.last, let text = row["p"] as? String,
              let price = Double(text), price.isFinite, price > 0,
              let millis = row["T"] as? Double, millis.isFinite else { throw FeedError.invalidResponse }
        return Observation(time: Date(timeIntervalSince1970: millis / 1000), price: price)
    }
}

public struct CurvePoint: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}

public enum CurveGeometry {
    public static func normalize(_ values: [Double]) -> [CurvePoint] {
        let valid = values.filter { $0.isFinite && $0 > 0 }
        guard valid.count >= 2, let low = valid.min(), let high = valid.max() else { return [] }
        let span = high - low
        return valid.enumerated().map { index, value in
            CurvePoint(x: Double(index) / Double(valid.count - 1), y: span == 0 ? 0.5 : (value - low) / span)
        }
    }
}

public enum CurveActivity {
    public static func isUpdating(lastPointAt: Date?, receivedAt: Date?, now: Date) -> Bool {
        guard let lastPointAt, let receivedAt else { return false }
        return (-5...120).contains(now.timeIntervalSince(lastPointAt)) && (0...12).contains(now.timeIntervalSince(receivedAt))
    }
}
