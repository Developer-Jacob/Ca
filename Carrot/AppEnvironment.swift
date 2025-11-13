//
//  AppEnvironment.swift
//  Carrot
//
//  Created by Jacob on 11/13/25.
//

import Foundation

struct AppEnvironment {
    let searchUseCase: SearchBooksUseCase
    let detailUseCase: FetchBookDetailUseCase
    let imageLoader: ImageLoading
    
    static func makeDefault() -> AppEnvironment {
        let dataSource = DefaultBookDataSource(urlSession: URLSession.shared)
        let repository = DefaultBookRepository(dataSource: dataSource)
        let cacheConfiguration = ImageCacheConfiguration()
        
        let memoryCacheProvider = ImageCacheProvider(
            configuration: ImageCacheConfiguration(),
            memoryCache: SystemMemoryCache(capacity: cacheConfiguration.memoryCapacity),
            diskCache:
                DiskCache(
                    capacity: cacheConfiguration.diskCapacity,
                    directoryName: cacheConfiguration.diskDirectoryName,
                    cacheExpirationInterval: cacheConfiguration.defaultTTL,
                    policy: LRUDiskEvictionPolicy()
                )
        )
        
        return AppEnvironment(
            searchUseCase: DefaultSearchBooksUseCase(bookRepository: repository),
            detailUseCase: DefaultFetchBookDetailUseCase(bookRepository: repository),
            imageLoader: ImageService(
                cacheProvider: memoryCacheProvider,
                remoteProvider: DefaultImageRemoteProvider()
            )
        )
    }
}
