//
//  MemoryCache.swift
//  Carrot
//
//  Created by Jacob on 11/11/25.
//

import Foundation

protocol MemoryCaching {
    func data(for key: String, now: Date) async -> CacheItem?
    func store(_ data: Data, for key: String) async
}

actor SystemMemoryCache: MemoryCaching {
    private let cache: NSCache<NSString, NSData>

    init(capacity: Int) {
        let cache = NSCache<NSString, NSData>()
        cache.totalCostLimit = capacity
        self.cache = cache
    }

    func data(for key: String, now: Date) async -> CacheItem? {
        guard let data = cache.object(forKey: key as NSString) as Data? else { return nil }
        return .init(data: data, expirationDate: nil)
    }

    func store(_ data: Data, for key: String) async {
        cache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
    }

    func remove(for key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    func removeAll() {
        cache.removeAllObjects()
    }
}
