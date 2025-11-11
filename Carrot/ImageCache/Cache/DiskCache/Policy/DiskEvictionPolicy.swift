//
//  DiskEvictionPolicy.swift
//  Carrot
//
//  Created by Jacob on 11/11/25.
//

/// 디스크 캐시 만료 정책, 주입을 위해
protocol DiskEvictionPolicy {
    func keysToEvict(from manifest: DiskCacheManifest, capacity: Int) -> [String]
}

/// 디스크 만료 정책 구현체
struct LRUDiskEvictionPolicy: DiskEvictionPolicy {
    func keysToEvict(from manifest: DiskCacheManifest, capacity: Int) -> [String] {
        // 용량 넘었을떄 제거대상 존재
        guard manifest.totalSize > capacity else { return [] }
        // 오래된 순서로 정렬
        let sortedRecords = manifest.records.sorted { $0.value.lastAccessDate < $1.value.lastAccessDate }
        var evicted: [String] = []
        var currentSize = manifest.totalSize
        // 최대 용량보다 적을때까지
        for (key, record) in sortedRecords {
            if currentSize <= capacity { break }
            evicted.append(key)
            currentSize -= record.fileSize
        }
        return evicted
    }
}
