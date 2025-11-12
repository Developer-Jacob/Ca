//
//  ImageCacheProvider.swift
//  Carrot
//
//  Created by Jacob on 11/11/25.
//

import Foundation

actor ImageCacheProvider {
    private let diskCache: DiskCaching
    private let memoryCache: MemoryCaching
    private let configuration: ImageCacheConfiguration
    
    init(configuration: ImageCacheConfiguration) {
        let capacity = configuration.diskCapacity
        self.diskCache = DiskCache(capacity: capacity, directoryName: configuration.diskDirectoryName)
        self.memoryCache = MemoryCache(capacity: capacity)
        self.configuration = configuration
    }
    
    private func cacheKey(for url: URL) -> String {
        url.absoluteString
    }
    
    /// 메모리 → 디스크 순으로 조회해 데이터를 반환
    func data(for url: URL) async -> CacheItem? {
        let key = cacheKey(for: url)
        let now = Date.now
        
        if let item = await memoryCache.data(for: key, now: now) {
            print("Carrot: Memory cache hit. key: \(key)")
            return item
        }
        
        if let item = await diskCache.data(for: key, now: now) {
            // 디스크만 존재시 메모리 업데이트
            print("Carrot: Disk cache hit. key: \(key)")
            await memoryCache.store(item.data, for: key, expirationDate: item.expirationDate)
            return item
        }
        return nil
    }
    
    func store(_ data: Data, for url: URL) async {
        let key = cacheKey(for: url)
        let now = Date.now
        let expirationDate = now.addingTimeInterval(configuration.defaultTTL)
        
        // 단일 파일이 최대용량 보다 크다면 캐시 하지 않음
        if data.count <= configuration.memoryCapacity {
            await memoryCache.store(data, for: key, expirationDate: expirationDate)
        }
        
        // 단일 파일이 최대용량 보다 크다면 캐시 하지 않음
        if data.count <= configuration.diskCapacity {
            await diskCache.store(data, for: key, expirationDate: expirationDate)
        }
    }
}


