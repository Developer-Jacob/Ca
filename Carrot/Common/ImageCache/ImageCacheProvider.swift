//
//  ImageCacheProvider.swift
//  Carrot
//
//  Created by Jacob on 11/11/25.
//

import Foundation

final class ImageCacheProvider {
    private let diskCache: DiskCaching
    private let memoryCache: MemoryCaching
    private let configuration: ImageCacheConfiguration
    
    init(configuration: ImageCacheConfiguration, memoryCache: MemoryCaching, diskCache: DiskCaching) {
        self.diskCache = diskCache
        self.memoryCache = memoryCache
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
            return item
        }
        
        if let item = await diskCache.data(for: key, now: now) {
            await memoryCache.store(item.data, for: key)    // 디스크만 존재시 메모리 업데이트
            return item
        }
        return nil
    }
    
    func store(_ data: Data, for url: URL) async {
        let key = cacheKey(for: url)
        
        await memoryCache.store(data, for: key)
        
        Task.detached(priority: .utility) { [weak self] in      // 디스크 캐시 우선순위 낮음
            await self?.diskCache.store(data, for: key)
        }
    }
}


