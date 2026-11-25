import Foundation

/// Reads an exchange-rates-uy server (github.com/guillecura/exchange-rates-uy): the bank's and the market's rates, the
/// pairs, a pair's history, a conversion. The same API and names as the server and its JavaScript client.
///
///     let rates = RatesClient(baseURL: URL(string: "https://your-server/api")!, key: "…")
///     let bank = try await rates.official()          // the BCU's pesos per unit, buying and selling
///     let usd = try await rates.history("USD/UYU", from: "2026-01-01")
///
/// A key in a phone app can be read out of it: it says which app is asking, it does not protect the server.
public struct RatesClient: Sendable {
    public let baseURL: URL
    let key: String?
    let session: URLSession

    public init(baseURL: URL, key: String? = nil, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.key = key
        self.session = session
    }

    /// The bank's reading on `date` (YYYY-MM-DD, the last on or before it; today by default).
    public func official(date: String? = nil) async throws -> Official {
        try await call("official", ["date": date])
    }

    /// The market's table on `date`.
    public func market(date: String? = nil) async throws -> Market {
        try await call("market", ["date": date])
    }

    /// The server's pairs, each with both rates, on `date`.
    public func pairs(date: String? = nil) async throws -> [PairRate] {
        struct Answer: Decodable { let pairs: [PairRate] }
        let answer: Answer = try await call("pairs", ["date": date])
        return answer.pairs
    }

    /// The server's currencies, named in `lang`.
    public func currencies(lang: String? = nil) async throws -> [Currency] {
        struct Answer: Decodable { let currencies: [Currency] }
        let answer: Answer = try await call("currencies", ["lang": lang])
        return answer.currencies
    }

    /// One pair (`USD/UYU`), day by day, from one source. At most ten years per call.
    public func history(_ pair: String, from: String? = nil, to: String? = nil, source: Source = .official) async throws -> [HistoryDay] {
        struct Answer: Decodable { let days: [HistoryDay] }
        let path = "pairs/\(pair.uppercased().replacingOccurrences(of: "/", with: "-"))/history"
        let answer: Answer = try await call(path, ["from": from, "to": to, "source": source.rawValue])
        return answer.days
    }

    /// An amount in another currency.
    public func convert(_ amount: Double, from: String, to: String, date: String? = nil, source: Source = .market, side: Side? = nil) async throws -> Conversion {
        try await call("convert", [
            "amount": String(amount), "from": from, "to": to, "date": date, "source": source.rawValue, "side": side?.rawValue,
        ])
    }

    func call<T: Decodable>(_ path: String, _ query: [String: String?]) async throws -> T {
        var parts = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        let items = query.compactMap { key, value in value.map { URLQueryItem(name: key, value: $0) } }.sorted { $0.name < $1.name }
        parts.queryItems = items.isEmpty ? nil : items
        var request = URLRequest(url: parts.url!)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let key { request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization") }
        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw RatesError(status: status, message: (try? JSONDecoder().decode(Failure.self, from: data))?.error ?? "HTTP \(status)")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

/// The server's answer when it refuses: `{ "error": "…" }`.
private struct Failure: Decodable {
    let error: String
}
