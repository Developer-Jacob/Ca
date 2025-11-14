//
//  CacheRequestPerforming.swift
//  Carrot
//
//  Created by Jacob on 11/11/25.
//

import Foundation

protocol CacheRequestPerforming {
    func request(
        _ request: URLRequest,
        session: SessionProtocol,
        cache: URLCache
    ) async throws -> Data
}

/// 서버가 제공하는 HTTP 캐시 정책(ETag, Cache-Control 등)을 신뢰하여 동작하는 요청 수행자입니다.
///
/// 이 전략은 서버가 제공하는 캐시 제어 헤더를 기반으로 `URLSession`의
/// 기본 캐싱 메커니즘을 그대로 사용합니다.
/// `URLSessionConfiguration.urlCache`가 활성화되어 있을 경우,
/// 자동으로 조건부 요청(`If-None-Match`, `If-Modified-Since`)을 보내며,
/// 서버가 변경 사항이 없다고 판단하면 `304 Not Modified` 응답을 반환합니다.
///
/// 개발자가 직접 캐시를 관리하지 않아도 되며,
/// 서버가 신선도(freshness)를 관리할 때 가장 적합합니다.
///
/// 예시:
/// ```swift
/// let performer = ServerDrivenRequestPerformer()
/// let result: BookList = try await performer.request(endpoint, using: session, cache: .shared)
/// ```
///
/// - SeeAlso: `CacheFirstRequestPerformer`, `NetworkFirstRequestPerformer`
struct ServerDrivenRequestPerformer: CacheRequestPerforming {
    func request(
        _ request: URLRequest,
        session: SessionProtocol,
        cache: URLCache
    ) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        return data
    }
}

/// 캐시된 데이터를 우선적으로 사용하는 요청 수행자입니다.
///
/// 이 전략은 서버의 `URLCache` 자동 캐시 메커니즘을 사용하지 않으며,
/// 클라이언트가 직접 캐시를 관리합니다. 즉, 서버가 `ETag`나 `Cache-Control`
/// 헤더를 내려주더라도 해당 정보를 기반으로 자동 검증(`304`)을 수행하지 않습니다.
///
/// 먼저 `URLCache`를 조회하여 캐시된 응답이 존재할 경우,
/// 네트워크 요청을 보내지 않고 즉시 캐시 데이터를 반환합니다.
/// 캐시가 없을 경우에만 네트워크 요청을 수행하며,
/// 성공 시 응답 데이터를 캐시에 저장합니다.
///
/// 주로 목록 화면이나 변경이 적은 정적 데이터 요청에 사용됩니다.
/// 최신성이 약간 떨어져도 빠른 응답 속도가 중요한 경우 적합합니다.
///
/// 예시:
/// ```swift
/// let performer = CacheFirstRequestPerformer()
/// let result: BookList = try await performer.request(endpoint, using: session, cache: .shared)
/// ```
///
/// - Important: 서버의 HTTP 캐시(ETag, Cache-Control)는 무시됩니다.
/// - SeeAlso: `NetworkFirstRequestPerformer`, `ReloadRequestPerformer`
struct CacheFirstRequestPerformer: CacheRequestPerforming {
    func request(
        _ request: URLRequest,
        session: SessionProtocol,
        cache: URLCache
    ) async throws -> Data {
        // 캐시 먼저
        if let cached = cache.cachedResponse(for: request) {
            return cached.data
        }

        // 없으면 네트워크
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        // 수동 캐시
        let cachedResponse = CachedURLResponse(response: httpResponse, data: data)
        cache.storeCachedResponse(cachedResponse, for: request)
        return data
    }
}

/// 네트워크 요청을 우선적으로 시도하되,
/// 실패 시 캐시된 데이터를 폴백으로 사용하는 요청 수행자입니다.
///
/// 이 전략은 서버의 `URLCache` 자동 캐시 기능을 사용하지 않으며,
/// 클라이언트 측에서 직접 캐시를 관리합니다. 따라서 서버의
/// `ETag`, `Last-Modified`, `Cache-Control` 헤더는 고려되지 않습니다.
///
/// 항상 네트워크 요청을 먼저 시도하며, 요청이 실패할 경우
/// `URLCache`에서 기존 캐시 데이터를 반환합니다.
/// 네트워크 성공 시 최신 데이터를 캐시에 덮어씁니다.
///
/// 네트워크가 불안정한 환경에서 오프라인 대응이 필요한 경우 적합합니다.
///
/// 예시:
/// ```swift
/// let performer = NetworkFirstRequestPerformer()
/// let result: BookDetail = try await performer.request(endpoint, using: session, cache: .shared)
/// ```
///
/// - Important: 서버의 HTTP 캐시 정책은 무시되며, 캐시는 클라이언트가 직접 관리합니다.
/// - SeeAlso: `CacheFirstRequestPerformer`, `ReloadRequestPerformer`
struct NetworkFirstRequestPerformer: CacheRequestPerforming {
    func request(
        _ request: URLRequest,
        session: SessionProtocol,
        cache: URLCache
    ) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }

            let cachedResponse = CachedURLResponse(response: httpResponse, data: data)
            cache.storeCachedResponse(cachedResponse, for: request)

            return data
        } catch {
            // 폴백
            if let cached = cache.cachedResponse(for: request) {
                return cached.data
            }
            throw error
        }
    }
}

/// 항상 최신 데이터를 가져오며 캐시를 무시하는 요청 수행자입니다.
///
/// 이 전략은 서버의 `URLCache` 자동 캐시 기능을 사용하지 않으며,
/// 클라이언트가 명시적으로 `URLRequest.CachePolicy.reloadIgnoringLocalCacheData`
/// 를 설정하여 모든 캐시를 무시하고 네트워크 요청을 수행합니다.
///
/// 캐시된 데이터를 사용하지 않기 때문에 항상 최신 데이터를 보장하지만,
/// 네트워크 요청 실패 시 대체 수단이 없습니다.
/// 오프라인 환경에서는 오류가 발생할 수 있습니다.
///
/// 예시:
/// ```swift
/// let performer = ReloadRequestPerformer()
/// let result: BookDetail = try await performer.request(endpoint, using: session, cache: .shared)
/// ```
///
/// - Important: 서버 및 로컬의 모든 캐시 정책을 무시합니다.
/// - SeeAlso: `NetworkFirstRequestPerformer`, `ServerDrivenRequestPerformer`
struct ReloadRequestPerformer: CacheRequestPerforming {
    func request(
        _ request: URLRequest,
        session: SessionProtocol,
        cache: URLCache
    ) async throws -> Data {

        var req = request
        req.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await session.data(for: req)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        return data
    }
}
