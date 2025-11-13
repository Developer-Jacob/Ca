//
//  DiskCache.swift
//  Carrot
//
//  Created by Jacob on 11/11/25.
//

import Foundation
import CryptoKit

struct DiskCacheRecord: Codable {
    let fileName: String            // 이름(해시)
    var fileSize: Int               // 사이즈
    var lastAccessDate: Date        // 마지막 접근 시각
    var accessCount: Int = 0        // 접근횟수
    var expirationDate: Date?       // 만료
}

struct DiskCacheManifest: Codable {
    var totalSize: Int  // 캐시 전체 사이즈
    var records: [String: DiskCacheRecord]  //URL: 캐시레코드

    static func empty() -> DiskCacheManifest {
        DiskCacheManifest(totalSize: 0, records: [:])
    }
}

protocol DiskCaching {
    func data(for key: String, now: Date) async -> CacheItem?
    func store(_ data: Data, for key: String) async
}

actor DiskCache: DiskCaching {
    private let fileManager = FileManager.default
    private let capacity: Int       // 최대사이즈
    private let cacheExpirationInterval: TimeInterval
    private let directoryURL: URL
    private let manifestURL: URL
    private var manifest: DiskCacheManifest
    private let policy: DiskEvictionPolicy  // 만료, 삭제 정책
    
    init(
        capacity: Int,
        directoryName: String,
        cacheExpirationInterval: TimeInterval,
        policy: DiskEvictionPolicy = LRUDiskEvictionPolicy()
    ) {
        self.capacity = capacity
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.directoryURL = caches.appendingPathComponent(directoryName, isDirectory: true)
        self.manifestURL = directoryURL.appendingPathComponent("manifest.json")
        self.cacheExpirationInterval = cacheExpirationInterval
        self.policy = policy
        
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
        if let data = try? Data(contentsOf: manifestURL),
           let decoded = try? JSONDecoder().decode(DiskCacheManifest.self, from: data) {
            manifest = decoded
        } else {
            manifest = .empty()
        }
    }

    func data(for key: String, now: Date) async -> CacheItem? {
        // 존재 여부 확인
        guard let record = manifest.records[key] else { return nil }
        
        // 만료 확인, 만료 시 제거
        if isExpired(record: record, now: now) {
            removeRecord(for: key)
            writeManifest()
            return nil
        }
        
        // data 변환 확인, invalid 시 제거
        guard let data = validData(from: record) else {
            removeRecord(for: key)
            writeManifest()
            return nil
        }
        
        // 접근, 속성값 갱신
        updateAccess(for: key, now: now)
        // 저장
        writeManifest()
        return CacheItem(data: data, expirationDate: record.expirationDate)
    }
    
    func store(_ data: Data, for key: String) async {
        let size = data.count
        // 단일파일 용량이 전체보다 크면 캐시x
        guard size <= capacity else { return }
        //해시로 네이밍, 덮어쓰기 가능
        let fileName = hashedName(for: key)
        let fileURL = fileURL(fileName: fileName)
        do {
            // 파일 선저장 후 캐시 속성값 업뎃
            try data.write(to: fileURL, options: .atomic)
        } catch {
            return
        }
        
        let now = Date.now
        let expirationDate = now.addingTimeInterval(cacheExpirationInterval)
        let record = DiskCacheRecord(
            fileName: fileName,
            fileSize: size,
            lastAccessDate: now,
            accessCount: 1,
            expirationDate: expirationDate
        )
        
        // 이전파일존재시
        if let existing = manifest.records[key] {
            // 이미 덮어쓰기 완료, 사이즈만 갱신
            manifest.totalSize -= existing.fileSize
        }
        // manifest 갱신
        manifest.records[key] = record
        manifest.totalSize += size
        
        // 정책에 맞게 제거대상 찾기
        let evictedKeys = policy.keysToEvict(from: manifest, capacity: capacity)
        for key in evictedKeys {
            removeRecord(for: key)
        }
        writeManifest()
    }
}

extension DiskCache {
    private func isExpired(record: DiskCacheRecord, now: Date) -> Bool {
        // 만료일 없으면 무제한
        guard let expirationDate = record.expirationDate else { return false }
        guard expirationDate < now else { return false }
        return true
    }
    
    private func validData(from record: DiskCacheRecord) -> Data? {
        let url = fileURL(fileName: record.fileName)
        return try? Data(contentsOf: url)
    }
    
    private func updateAccess(for key: String, now: Date) {
        guard var record = manifest.records[key] else { return }
        record.lastAccessDate = now
        record.accessCount += 1
        manifest.records[key] = record
    }
    
    private func removeRecord(for key: String) {
        guard let record = manifest.records[key] else { return }
        manifest.totalSize -= record.fileSize
        removeFile(record: record)
    }
    
    private func removeFile(record: DiskCacheRecord) {
        let fileURL = fileURL(fileName: record.fileName)
        try? fileManager.removeItem(at: fileURL)
    }
    
    private func writeManifest() {
        guard let data = try? JSONEncoder().encode(manifest) else { return }
        try? data.write(to: manifestURL, options: .atomic)
    }
    
    private func fileURL(fileName: String) -> URL {
        directoryURL.appendingPathComponent(fileName, isDirectory: false)
    }
    
    private func hashedName(for key: String) -> String {
        let digest = SHA256.hash(data: Data(key.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
