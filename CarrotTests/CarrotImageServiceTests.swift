//
//  CarrotImageServiceTests.swift
//  Carrot
//
//  Created by Jacob on 11/14/25.
//

import XCTest
@testable import Carrot

final class CarrotImageServiceTests: XCTestCase {
    private let url = URL(string: "https://itbook.store/img/books/9781484212820.png")!

    func test_이미지서비스_메모리캐시히트시_디스크미조회_네트워크미호출() async {
        let memoryData = Data("memory-hit".utf8)
        let (sut, memoryCache, diskCache, remote) = await makeSUT(memoryData: memoryData)

        let _ = await sut.loadImageData(from: url)

        async let fetchCount = remote.fetchCount()
        async let lookupKeys = diskCache.recordedLookupKeys()
        async let storedData = memoryCache.storedData(for: cacheKey)

        let (count, keys, memoryStored) = await (fetchCount, lookupKeys, storedData)

        XCTAssertEqual(count, 0)
        XCTAssertTrue(keys.isEmpty)
        XCTAssertEqual(memoryStored, memoryData)
    }

    func test_이미지서비스_디스크캐시히트시_메모리워밍_네트워크미호출() async {
        let diskData = Data("disk-hit".utf8)
        let diskItem = CacheItem(data: diskData, expirationDate: Date().addingTimeInterval(60))
        let (sut, memoryCache, diskCache, remote) = await makeSUT(diskItem: diskItem)

        let data = await sut.loadImageData(from: url)

        let fetchCount = await remote.fetchCount()
        let memoryStoredData = await memoryCache.storedData(for: cacheKey)
        let lookupKeys = await diskCache.recordedLookupKeys()

        XCTAssertEqual(data, diskData)
        XCTAssertEqual(fetchCount, 0)
        XCTAssertEqual(memoryStoredData, diskData)
        XCTAssertEqual(lookupKeys, [cacheKey])
    }

    func test_이미지서비스_캐시미스시_네트워크패치후_캐시에저장() async {
        let remoteData = Data("remote-fetch".utf8)
        let (sut, memoryCache, diskCache, remote) = await makeSUT(remoteData: remoteData)

        let data = await sut.loadImageData(from: url)

        let fetchCount = await remote.fetchCount()
        let memoryStoredData = await memoryCache.storedData(for: cacheKey)

        await diskCache.waitForStoreCount(atLeast: 1)
        let diskStoredData = await diskCache.storedData(for: cacheKey)

        XCTAssertEqual(data, remoteData)
        XCTAssertEqual(fetchCount, 1)
        XCTAssertEqual(memoryStoredData, remoteData)
        XCTAssertEqual(diskStoredData, remoteData)
    }

    func test_이미지서비스_메모리와디스크모두있을시_메모리우선() async {
        let memoryData = Data("memory".utf8)
        let diskData = Data("disk".utf8)
        let diskItem = CacheItem(data: diskData, expirationDate: Date().addingTimeInterval(60))
        let (sut, memoryCache, diskCache, remote) = await makeSUT(memoryData: memoryData, diskItem: diskItem)

        let data = await sut.loadImageData(from: url)

        // 비동기 결과를 먼저 값으로 꺼낸다
        let fetchCount = await remote.fetchCount()
        let lookupKeys = await diskCache.recordedLookupKeys()
        let memoryStoredData = await memoryCache.storedData(for: cacheKey)

        XCTAssertEqual(data, memoryData)
        XCTAssertEqual(fetchCount, 0)
        XCTAssertTrue(lookupKeys.isEmpty)
        XCTAssertEqual(memoryStoredData, memoryData)
    }

    private var cacheKey: String { url.absoluteString }

    private func makeSUT(
        memoryData: Data? = nil,
        diskItem: CacheItem? = nil,
        remoteData: Data = Data("remote-default".utf8)
    ) async -> (ImageService, MockMemoryCache, MockDiskCache, MockRemoteProvider) {
        let memoryCache = MockMemoryCache()
        if let memoryData {
            await memoryCache.prime(memoryData, for: cacheKey)
        }
        let diskCache = MockDiskCache()
        if let diskItem {
            await diskCache.prime(diskItem, for: cacheKey)
        }
        let remote = MockRemoteProvider(returning: remoteData)
        let configuration = ImageCacheConfiguration(
            memoryCapacity: 512 * 1024,
            diskCapacity: 512 * 1024,
            defaultTTL: 60,
            diskDirectoryName: "com.carrot.tests.imagecache"
        )
        let cacheProvider = ImageCacheProvider(
            configuration: configuration,
            memoryCache: memoryCache,
            diskCache: diskCache
        )
        let sut = ImageService(cacheProvider: cacheProvider, remoteProvider: remote)
        return (sut, memoryCache, diskCache, remote)
    }
}

private actor MockMemoryCache: MemoryCaching {
    private var storage: [String: Data] = [:]

    func data(for key: String, now: Date) async -> CacheItem? {
        guard let data = storage[key] else { return nil }
        return CacheItem(data: data, expirationDate: nil)
    }

    func store(_ data: Data, for key: String) async {
        storage[key] = data
    }

    func prime(_ data: Data, for key: String) async {
        storage[key] = data
    }

    func storedData(for key: String) async -> Data? {
        storage[key]
    }
}

private actor MockDiskCache: DiskCaching {
    private var items: [String: CacheItem] = [:]
    private var lookupKeys: [String] = []
    private var storeCallCount = 0

    func data(for key: String, now: Date) async -> CacheItem? {
        lookupKeys.append(key)
        return items[key]
    }

    func store(_ data: Data, for key: String) async {
        items[key] = CacheItem(data: data, expirationDate: nil)
        storeCallCount += 1
    }

    func prime(_ item: CacheItem, for key: String) async {
        items[key] = item
    }

    func recordedLookupKeys() async -> [String] {
        lookupKeys
    }

    func storedData(for key: String) async -> Data? {
        items[key]?.data
    }

    func waitForStoreCount(atLeast expected: Int) async {
        let timeout: TimeInterval = 1.0
        let pollInterval: TimeInterval = 0.1
        var elapsed: TimeInterval = 0
        
        // Task.detached 테스트를 위한 폴링
        while storeCallCount < expected && elapsed < timeout {
            try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
            elapsed += pollInterval
        }
    }
}

private actor MockRemoteProvider: ImageRemoteProvider {
    private let returnData: Data
    private var fetchCallCount = 0

    init(returning data: Data) {
        self.returnData = data
    }

    func fetchData(from url: URL) async -> Data {
        fetchCallCount += 1
        return returnData
    }

    func fetchCount() async -> Int {
        fetchCallCount
    }
}
