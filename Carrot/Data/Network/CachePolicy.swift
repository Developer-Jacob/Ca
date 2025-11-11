//
//  CachePolicy.swift
//  Carrot
//
//  Created by Jacob on 11/11/25.
//

enum CachePolicy {
    case serverDriven                      // 서버 캐시 지원
    case clientDriven(ClientCachePolicy)   // 서버 지원x or 못믿음
}

enum ClientCachePolicy {
    case cacheFirst
    case networkFirst
}
