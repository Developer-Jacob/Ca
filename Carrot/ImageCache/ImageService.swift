//
//  ImageService.swift
//  Carrot
//
//  Created by Jacob on 11/11/25.
//

import UIKit
import Foundation

protocol ImageLoading {
    func loadImage(from url: URL?) async -> UIImage?
    func loadImageData(from url: URL?) async -> Data?
}

/// 커스텀 메모리/디스크 캐시, 네트워크를 활요해 이미지를 반환하는 서비스
/// Memory -> Disk -> Remote
/// Disk 히트시 메모리에 저장해 일관성 유지
final actor ImageService: ImageLoading {
    private let cache: ImageCacheProvider
    private let remote: ImageRemoteProvider
    private var tasks: [URL: Task<Data?, Never>] = [:]

    /// - Parameters:
    ///   - cacheProvider: 메모리, 디스크 캐시
    ///   - remoteProvider: 네트워크
    init(
        cacheProvider: ImageCacheProvider,
        remoteProvider: ImageRemoteProvider = DefaultImageRemoteProvider()
    ) {
        self.cache = cacheProvider
        self.remote = remoteProvider
    }

    /// UIImage가 필요한 호출자를 위한 편의 함수
    /// Data 디코딩
    func loadImage(from url: URL?) async -> UIImage? {
        guard let data = await loadImageData(from: url) else { return nil }
        return UIImage(data: data)
    }

    /// 메모리 → 디스크 순으로 캐시를 조회, 없을 시 네트워크 fetch
    /// 네트워크 fetch 완료 시 캐싱
    func loadImageData(from url: URL?) async -> Data? {
        guard let url else { return nil }
        
        if let item = await cache.data(for: url) {
            return item.data
        }
        
        if let existing = tasks[url] {
            return await existing.value
        }

        let task = Task<Data?, Never> { [weak self] in
            guard let self else { return nil }
            defer { Task { await self.removeTask(for: url) } }
            do {
//                print("Carrot image cache: Remote fetch. key: \(url)")
                let data = try await self.remote.fetchData(from: url)
                await self.cache.store(data, for: url)
                return data
            } catch {
                return nil
            }
        }
        tasks[url] = task
        return await task.value
    }

    private func removeTask(for url: URL) {
        tasks[url] = nil
    }
}
