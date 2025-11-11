//
//  MemoryCache.swift
//  Carrot
//
//  Created by Jacob on 11/11/25.
//

import Foundation

protocol MemoryCaching {
    func data(for key: String, now: Date) async -> CacheItem?
    func store(_ data: Data, for key: String, expirationDate: Date?) async
}

actor MemoryCache: MemoryCaching {
    private let capacity: Int
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    func data(for key: String, now: Date) async -> CacheItem? {
        return nil
    }
    
    func store(_ data: Data, for key: String, expirationDate: Date?) async {
        let size = data.count
        guard size <= capacity else { return }
    }
}
