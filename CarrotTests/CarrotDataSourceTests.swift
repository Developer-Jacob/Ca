//
//  CarrotDataSourceTests.swift
//  Carrot
//
//  Created by Jacob on 11/11/25.
//

import XCTest
@testable import Carrot

final class BookDataSourceTests: XCTestCase {
    private func httpResponse(path: String) -> HTTPURLResponse {
        HTTPURLResponse(url: URL(string: "https://api.itbook.store\(path)")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    func test_데이터소스() async throws {
        let session = MockSession()
        session.nextData = sampleSearchJSONData()
        session.nextResponse = httpResponse(path: "/1.0/search/swift")
        let cache = URLCache(memoryCapacity: 1024 * 1024, diskCapacity: 0)
        let sut = DefaultBookDataSource(urlSession: session, cache: cache, cachePolicy: .serverDriven)

        let result: SearchResponseDTO = try await sut.perform(.search(query: "swift", page: 1))

        XCTAssertEqual(result.books.count, 1)
        XCTAssertEqual(session.recordedRequests.first?.url?.path, "/1.0/search/swift/1")
    }

    func test_데이터소스_로컬캐시우선() async throws {
        let session = MockSession()
        session.nextData = sampleSearchJSONData()
        session.nextResponse = httpResponse(path: "/1.0/search/swift")

        let cache = URLCache(memoryCapacity: 1024 * 1024, diskCapacity: 0)
        let request = ItBookAPI.search(query: "swift", page: 1).urlRequest!
        let cachedResponse = CachedURLResponse(response: httpResponse(path: "/1.0/search/swift"), data: sampleSearchJSONData())
        cache.storeCachedResponse(cachedResponse, for: request)

        let sut = DefaultBookDataSource(urlSession: session, cache: cache, cachePolicy: .clientDriven(.cacheFirst))

        let result: SearchResponseDTO = try await sut.perform(.search(query: "swift", page: 1))
        XCTAssertEqual(result.books.count, 1)
        XCTAssertTrue(session.recordedRequests.isEmpty)
    }

    func test_데이터소스_네트워크우선_실패시_캐시사용() async throws {
        let session = MockSession()
        session.nextError = URLError(.notConnectedToInternet)

        let cache = URLCache(memoryCapacity: 1024 * 1024, diskCapacity: 0)
        let request = ItBookAPI.search(query: "swift", page: 1).urlRequest!
        let cachedResponse = CachedURLResponse(response: httpResponse(path: "/1.0/search/swift"), data: sampleSearchJSONData())
        cache.storeCachedResponse(cachedResponse, for: request)

        let sut = DefaultBookDataSource(urlSession: session, cache: cache, cachePolicy: .clientDriven(.networkFirst))

        let result: SearchResponseDTO = try await sut.perform(.search(query: "swift", page: 1))
        XCTAssertEqual(result.books.count, 1)
        XCTAssertEqual(session.recordedRequests.count, 1)
    }
    
    func test_데이터소스_리스폰스에러() async {
        let session = MockSession()
        session.nextData = Data("{\"invalid\":true}".utf8)
        session.nextResponse = httpResponse(path: "/1.0/search/swift")
        let sut = DefaultBookDataSource(urlSession: session, cache: .shared, cachePolicy: .serverDriven)

        do {
            let _ : SearchResponseDTO = try await sut.perform(.search(query: "swift", page: 1))
        } catch {
            XCTAssertEqual((error as? APIError)?.errorDescription, APIError.decoding.errorDescription)
        }

    }
}
