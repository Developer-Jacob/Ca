//
//  DiskEvictionPolicy.swift
//  Carrot
//
//  Created by Jacob on 11/11/25.
//

/// 디스크 캐시 만료 정책
protocol DiskEvictionPolicy {
    func keysToEvict(from manifest: DiskCacheManifest, capacity: Int) -> [String]
}

/// 디스크 캐시 제거 정책: LRU(Least Recently Used)
///
/// 이 정책은 가장 오래 사용되지 않은 데이터부터 제거하여
/// 디스크 캐시의 용량을 초과하지 않도록 유지하는 전략
///
/// `LRUDiskEvictionPolicy`는 `DiskCacheManifest`에 기록된
/// `lastAccessDate` 값을 기준으로 정렬하여, 최근 접근이 없던 항목을
/// 우선적으로 제거합니다.
///
/// LRU는 캐시된 데이터 중 “사용 빈도가 낮은 것”을 자연스럽게 걸러내기 때문에
/// 이미지·데이터 캐싱 등에서 가장 널리 사용되는 방식입니다.
///
/// 동작 방식:
/// - `manifest.totalSize`가 `capacity`를 초과하면 정책이 작동합니다.
/// - `lastAccessDate` 기준 오름차순(오래된 순)으로 정렬합니다.
/// - 오래된 항목부터 제거하며, 총 용량이 허용 범위에 들어올 때까지 반복합니다.
///
/// 예시:
/// ```swift
/// let policy = LRUDiskEvictionPolicy()
/// let keys = policy.keysToEvict(from: manifest, capacity: 50_000_000) // 50MB
/// ```
///
/// - Important: 이 정책은 데이터의 '중요도'나 '파일 크기'를 고려하지 않고
///   순수하게 최근 접근 시간을 기준으로만 제거 대상을 판단합니다.
/// - SeeAlso: `DiskEvictionPolicy`, `DiskCache`, `LFUDiskEvictionPolicy` (사용 빈도 기반)
struct LRUDiskEvictionPolicy: DiskEvictionPolicy {
    func keysToEvict(from manifest: DiskCacheManifest, capacity: Int) -> [String] {
        // 용량 넘었을떄 제거대상 존재 확인
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
