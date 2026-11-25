# exchange-rates-uy for Swift

The iOS and macOS client for [exchange-rates-uy](https://github.com/guillecura/exchange-rates-uy): read the official rate (Banco Central del Uruguay: buying and selling) and the market's from an exchange-rates-uy server, yours or anybody's. The same API, names and shapes as the server and its JavaScript client.

## Install

Swift Package Manager, in Xcode (**File › Add Package Dependencies…**) or in `Package.swift`:

```swift
.package(url: "https://github.com/guillecura/exchange-rates-uy-swift", from: "1.0.0")
```

iOS 15, macOS 12, tvOS 15, watchOS 8. No dependencies.

## Use

```swift
import ExchangeRatesUY

let rates = RatesClient(baseURL: URL(string: "https://your-server/api")!, key: "…")

let bank = try await rates.official()                   // the BCU's pesos per unit
bank.perLocal["USD"]                                    // Spread(buy: 40.69, sell: 40.70)

let market = try await rates.market()                   // every currency per dollar
market.perLocal()["EUR"]                                // pesos per euro
market.credit.label                                     // "Rates By Exchange Rate API": show it beside its figures

let pairs = try await rates.pairs()                     // the server's pairs, each with both rates
let usd = try await rates.history("USD/UYU", from: "2026-01-01")
let result = try await rates.convert(100, from: "USD", to: "UYU", source: .official)
```

A refused call throws `RatesError` with the status and the server's own words.

| Call | Endpoint |
| --- | --- |
| `official(date:)` | `/official` |
| `market(date:)` | `/market` |
| `pairs(date:)` | `/pairs` |
| `currencies(lang:)` | `/currencies` |
| `history(_:from:to:source:)` | `/pairs/USD-UYU/history` |
| `convert(_:from:to:date:source:side:)` | `/convert` |

`date` is `YYYY-MM-DD`: the last reading on or before that day.

### The key

When the server only lets its own apps in (exchange-rates-uy's `access`), the key goes with every call as `Authorization: Bearer`. A key inside an app can be read out of it: it says which app is asking, it does not protect the server. Give each app its own and keep the server's keys for servers.

## License

MIT, by [Guille Cura](https://github.com/guillecura).
