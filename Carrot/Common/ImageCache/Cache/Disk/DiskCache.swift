//
//  DiskCache.swift
//  Carrot
//
//  Created by Jacob on 11/11/25.
//

import Foundation

/// 디스크 캐시 인터페이스
///
/// `DiskCaching`은 디스크 기반 캐시 구현을 추상화하는 프로토콜입니다.
protocol DiskCaching {
    /// 주어진 키에 해당하는 캐시 데이터를 조회합니다.
    ///
    /// - Parameters:
    ///   - key: 캐시 식별자 (예: URL)
    ///   - now: 만료 여부 판단에 사용할 현재 시각
    /// - Returns: 유효한 캐시가 존재하면 `CacheItem`, 없거나 만료/손상된 경우 `nil`
    func data(for key: String, now: Date) async -> CacheItem?
    /// 주어진 키에 데이터를 저장합니다.
    ///
    /// - Parameters:
    ///   - data: 디스크에 저장할 원본 데이터
    ///   - key: 캐시 식별자
    func store(_ data: Data, for key: String) async
}

// 디스크 캐시 구현
actor DiskCache: DiskCaching {
    // Configuration
    private let capacity: Int       // 최대사이즈
    private let cacheExpirationInterval: TimeInterval
    private let directoryURL: URL
    private let manifestURL: URL
    private var manifest: DiskCacheManifest // 메타데이터
    private let policy: DiskEvictionPolicy  // 만료, 삭제 정책
    
    // State
    private let manifestFlushInterval: TimeInterval
    private var isManifestDirty = false
    private var pendingFlushTask: Task<Void, Never>?
    
    // File i/o queue
    private let queue = DispatchQueue(label: "com.carrot.diskcache", qos: .utility)
    
    /// - Parameters:
    ///   - capacity: 전체 캐시 허용 용량(바이트)
    ///   - directoryName: 캐시 파일이 저장될 디렉터리 이름 (Caches 디렉터리 하위)
    ///   - cacheExpirationInterval: 기본 만료 시간 (예: 24 * 60 * 60)
    ///   - policy: 용량 초과 시 제거에 사용할 정책 (기본: LRU)
    ///   - manifestFlushInterval: manifest를 디스크에 쓰는 주기
    init(
        capacity: Int,
        directoryName: String,
        cacheExpirationInterval: TimeInterval,
        policy: DiskEvictionPolicy = LRUDiskEvictionPolicy(),
        manifestFlushInterval: TimeInterval = 1.0
    ) {
        self.capacity = capacity
        self.cacheExpirationInterval = cacheExpirationInterval
        self.policy = policy
        self.manifestFlushInterval = manifestFlushInterval
        
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.directoryURL = caches.appendingPathComponent(directoryName, isDirectory: true)
        self.manifestURL = directoryURL.appendingPathComponent("manifest.json")
        
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
        
        if let data = try? Data(contentsOf: manifestURL),
           let decoded = try? JSONDecoder().decode(DiskCacheManifest.self, from: data) {
            manifest = decoded
        } else {
            manifest = .empty()
        }
    }
    
    // MARK: - Public
    
    /// 주어진 키에 해당하는 캐시 데이터를 조회합니다.
    ///
    /// 순서:
    /// 1. `manifest`에서 레코드를 찾습니다.
    /// 2. 만료 여부를 확인하고, 만료된 경우 레코드 및 파일을 제거합니다.
    /// 3. 디스크에서 실제 파일을 읽습니다.
    /// 4. 읽기 성공 시 접근 시간/카운트를 갱신하고 `CacheItem`을 반환합니다.
    func data(for key: String, now: Date) async -> CacheItem? {
        
        // 1. `manifest`에서 레코드를 찾습니다.
        guard let record = manifest.records[key] else { return nil }
        
        // 2. 만료 여부를 확인하고, 만료된 경우 레코드 및 파일을 제거합니다.
        if isExpired(record: record, now: now) {
            removeRecord(for: key)
            return nil
        }

        // 3. 디스크에서 실제 파일을 읽습니다.
        let url = fileURL(fileName: record.fileName)
        guard let data = await readData(url: url) else {
            // invalid 시 제거
            removeRecord(for: key)
            return nil
        }
        
        // 4. 읽기 성공 시 접근 시간/카운트를 갱신하고 `CacheItem`을 반환합니다.
        if var current = manifest.records[key] {
            current.lastAccessDate = now
            current.accessCount += 1
            manifest.records[key] = current
            markManifestDirty()
        }

        return CacheItem(data: data, expirationDate: record.expirationDate)
    }
    
    /// 주어진 키로 데이터를 디스크에 저장하고 manifest를 갱신합니다.
    ///
    /// 순서:
    /// 1. 용량(capacity)을 초과하는 단일 파일은 저장하지 않습니다.
    /// 2. 파일명을 해시(`SHA256`)로 변환해 디스크에 저장합니다.
    /// 3. 기존 레코드가 있다면 용량에서 차감한 뒤 새 레코드로 덮어씁니다.
    /// 4. 전체 용량이 초과된 경우, `DiskEvictionPolicy`에 따라 제거 대상을 선정합니다.
    /// 5. 제거된 파일을 삭제하고 manifest를 더티 마킹합니다.
    ///
    /// - Parameters:
    ///   - data: 저장할 데이터
    ///   - key: 캐시 키
    func store(_ data: Data, for key: String) async {
        let size = data.count
        let now = Date.now
        let expirationDate = now.addingTimeInterval(cacheExpirationInterval)
        
        /// 1. 용량(capacity)을 초과하는 단일 파일은 저장하지 않습니다.
        guard size <= capacity else { return }  // 단일파일 용량이 전체보다 크면 캐시x
        
        /// 2. 파일명을 해시(`SHA256`)로 변환해 디스크에 저장합니다.
        let fileName = key.hashedSHA256
        let url = fileURL(fileName: fileName)
        guard await writeData(data, url: url) else { return }
        
        let record = DiskCacheRecord(
            fileName: fileName,
            fileSize: size,
            lastAccessDate: now,
            accessCount: 1,
            expirationDate: expirationDate
        )
        
        /// 3. 기존 레코드가 있다면 용량에서 차감한 뒤 새 레코드로 덮어씁니다.
        if let existing = manifest.records[key] {
            manifest.totalSize -= existing.fileSize
            if manifest.totalSize < 0 { manifest.totalSize = 0 }
        }
        
        /// 4. 전체 용량이 초과된 경우, `DiskEvictionPolicy`에 따라 제거 대상을 선정합니다.
        manifest.records[key] = record
        manifest.totalSize += size
        
        /// 5. 제거된 파일을 삭제하고 manifest를 더티 마킹합니다.
        let evictedKeys = policy.keysToEvict(from: manifest, capacity: capacity)
        for key in evictedKeys {
            removeRecord(for: key, markDirty: false)
        }
        markManifestDirty()
    }
}

// MARK: - Expiration

extension DiskCache {
    /// 레코드가 만료되었는지 여부를 확인합니다.
    ///
    /// - Parameters:
    ///   - record: 만료 여부를 검사할 레코드
    ///   - now: 현재 시각
    /// - Returns: 만료되었으면 `true`, 아니면 `false`
    ///
    private func isExpired(record: DiskCacheRecord, now: Date) -> Bool {
        guard let expirationDate = record.expirationDate else { return false }  // 만료일 없으면 무제한
        guard expirationDate < now else { return false }
        return true
    }
}

// MARK: - Manifest update

extension DiskCache {
    /// manifest에서 레코드를 제거하고, 대응하는 파일도 삭제합니다.
    ///
    /// - Parameters:
    ///   - key: 제거할 레코드의 키
    ///   - markDirty: 제거 후 manifest를 더티 마킹할지 여부
    private func removeRecord(for key: String, markDirty: Bool = true) {
        guard let record = manifest.records[key] else { return }
        
        manifest.totalSize -= record.fileSize
        if manifest.totalSize < 0 { manifest.totalSize = 0 }
        
        manifest.records[key] = nil
        
        let fileURL = fileURL(fileName: record.fileName)
        removeFile(url: fileURL)
        
        if markDirty {
            markManifestDirty()
        }
    }
    
    /// manifest가 변경되었음을 표시하고,
    /// 일정 시간 후 디스크에 반영되도록 예약합니다.
    private func markManifestDirty() {
        isManifestDirty = true
        scheduleManifestFlush()
    }
    
    private func flushManifestIfNeeded() {
        guard isManifestDirty else { return }
        isManifestDirty = false
        pendingFlushTask = nil
        writeManifest()
    }
    
    private func fileURL(fileName: String) -> URL {
        directoryURL.appendingPathComponent(fileName, isDirectory: false)
    }
    
    private func scheduleManifestFlush() {
        pendingFlushTask?.cancel()
        pendingFlushTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(nanoseconds: UInt64(manifestFlushInterval * 1_000_000_000))
                try Task.checkCancellation()
                await self.flushManifestIfNeeded()
            } catch {
                // 취소, 슬립 중 에러 발생 무시
            }
        }
    }
}

// MARK: - I/O

extension DiskCache {
    private func writeManifest() {
        let snapshot = manifest
        let url = manifestURL
        queue.async {
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            try? data.write(to: url, options: .atomic)
        }
    }

    private func readData(url: URL) async -> Data? {
        return await withCheckedContinuation { continuation in
            queue.async {
                let data = try? Data(contentsOf: url)
                continuation.resume(returning: data)
            }
        }
    }

    private func writeData(_ data: Data, url: URL) async -> Bool {
        return await withCheckedContinuation { continuation in
            queue.async {
                do {
                    try data.write(to: url, options: .atomic)
                    continuation.resume(returning: true)
                } catch {
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    private func removeFile(url: URL) {
        queue.async {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
