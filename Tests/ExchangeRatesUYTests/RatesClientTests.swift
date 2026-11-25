import XCTest
@testable import ExchangeRatesUY

/// Answers every request from a function, so the client is tested against the server's real shapes.
final class Stub: URLProtocol {
    nonisolated(unsafe) static var answer: (URLRequest) -> (Int, String) = { _ in (404, "{}") }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let (status, body) = Stub.answer(request)
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

final class RatesClientTests: XCTestCase {
    func client(key: String? = "app-key") -> RatesClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [Stub.self]
        return RatesClient(baseURL: URL(string: "https://rates.example/api")!, key: key, session: URLSession(configuration: config))
    }

    func testOfficialWithTheKey() async throws {
        Stub.answer = { req in
            XCTAssertEqual(req.url?.absoluteString, "https://rates.example/api/official?date=2026-11-25")
            XCTAssertEqual(req.value(forHTTPHeaderField: "Authorization"), "Bearer app-key")
            return (200, #"{"date":"2026-11-25","day":"2026-11-24","perLocal":{"UYU":{"buy":1,"sell":1},"USD":{"buy":39.5,"sell":41.9}},"published":{},"quote":"UYU","source":"https://www.bcu.gub.uy"}"#)
        }
        let bank = try await client().official(date: "2026-11-25")
        XCTAssertEqual(bank.perLocal["USD"], Spread(buy: 39.5, sell: 41.9))
    }

    func testMarketAndPesosPerUnit() async throws {
        Stub.answer = { _ in (200, #"{"date":"2026-11-25","day":"2026-11-24","perUsd":{"USD":1,"UYU":40.5,"EUR":0.81},"base":"USD","credit":{"label":"Rates By Exchange Rate API","href":"https://www.exchangerate-api.com"}}"#) }
        let market = try await client().market()
        XCTAssertEqual(market.perLocal()["USD"], 40.5)
        XCTAssertEqual(market.perLocal()["EUR"]!, 50, accuracy: 1e-9)
        XCTAssertEqual(market.credit.label, "Rates By Exchange Rate API")
    }

    func testHistoryPath() async throws {
        Stub.answer = { req in
            XCTAssertEqual(req.url?.path, "/api/pairs/USD-UYU/history")
            return (200, #"{"days":[{"day":"2026-11-24","buy":39.5,"sell":41.9}]}"#)
        }
        let days = try await client().history("usd/uyu", from: "2026-11-01")
        XCTAssertEqual(days.map(\.day), ["2026-11-24"])
    }

    func testTheServersErrors() async {
        Stub.answer = { _ in (403, #"{"error":"this API is for its allowed sites and keys"}"#) }
        do {
            _ = try await client(key: nil).pairs()
            XCTFail("a 403 throws")
        } catch let e as RatesError {
            XCTAssertEqual(e.status, 403)
            XCTAssertEqual(e.message, "this API is for its allowed sites and keys")
        } catch {
            XCTFail("\(error)")
        }
    }
}
