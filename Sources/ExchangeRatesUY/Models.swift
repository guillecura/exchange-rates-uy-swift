import Foundation

/// Buying and selling: the bank's shape.
public struct Spread: Codable, Equatable, Sendable {
    public let buy: Double
    public let sell: Double
}

/// The bank's reading on or before a day: each currency in pesos, and what it published against the dollar.
public struct Official: Codable, Equatable, Sendable {
    public let date: String
    public let day: String
    public let perLocal: [String: Spread]
    public let published: [String: Spread]
    public let quote: String
    public let source: String
}

/// The market's credit, which its licence asks to show beside its figures.
public struct Credit: Codable, Equatable, Sendable {
    public let label: String
    public let href: String
}

/// The market's table on or before a day: how many of each currency buy one dollar.
public struct Market: Codable, Equatable, Sendable {
    public let date: String
    public let day: String
    public let perUsd: [String: Double]
    public let base: String
    public let credit: Credit

    /// Pesos (or any `local`) per unit of each currency: the local column over the currency's.
    public func perLocal(_ local: String = "UYU") -> [String: Double] {
        guard let l = perUsd[local], l > 0 else { return [:] }
        return perUsd.filter { $0.value > 0 }.mapValues { l / $0 }
    }
}

public struct OfficialRate: Codable, Equatable, Sendable {
    public let day: String
    public let buy: Double
    public let sell: Double
}

public struct MarketRate: Codable, Equatable, Sendable {
    public let day: String
    public let rate: Double
}

/// One of the server's pairs with both rates.
public struct PairRate: Codable, Equatable, Sendable {
    public let pair: String
    public let base: String
    public let quote: String
    public let favourite: Bool
    public let official: OfficialRate?
    public let market: MarketRate?
}

/// One of the server's currencies: its name in the language asked, its mark, its places, whether the bank quotes it.
public struct Currency: Codable, Equatable, Sendable {
    public let iso: String
    public let name: String
    public let symbol: String
    public let places: Int
    public let official: Bool
}

/// One day of a pair's history.
public struct HistoryDay: Codable, Equatable, Sendable {
    public let day: String
    public let buy: Double
    public let sell: Double
}

public struct Conversion: Codable, Equatable, Sendable {
    public let amount: Double
    public let from: String
    public let to: String
    public let date: String
    public let day: String
    public let source: String
    public let side: String?
    public let rate: Double
    public let result: Double
}

public enum Source: String, Sendable {
    case official, market
}

public enum Side: String, Sendable {
    case buy, sell, mid
}

/// What a call that failed says: the status and the server's own words.
public struct RatesError: Error, Equatable, LocalizedError {
    public let status: Int
    public let message: String
    public var errorDescription: String? { message }
}
