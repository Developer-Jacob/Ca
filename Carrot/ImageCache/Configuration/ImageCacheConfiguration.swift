//
//  ImageCacheConfiguration.swift
//  Carrot
//
//  Created by Jacob on 11/11/25.
//

import Foundation

struct ImageCacheConfiguration {
    let memoryCapacity: Int
    let diskCapacity: Int
    let defaultTTL: TimeInterval
    let diskDirectoryName: String

    /// - Parameters:
    ///   - memoryCapacity: 메모리 캐시 용량
    ///   - diskCapacity: 디스크 캐시 용량
    ///   - defaultTTL: 기본 만료 시간
    ///   - diskDirectoryName: 디스크 캐시 디렉토리
    init(
        memoryCapacity: Int = Const.defaultMemoryCapacity,
        diskCapacity: Int = Const.defaultDiskCapacity,
        defaultTTL: TimeInterval = Const.defaultTTL,
        diskDirectoryName: String = Const.defaultDirectoryName
    ) {
        self.memoryCapacity = memoryCapacity
        self.diskCapacity = diskCapacity
        self.defaultTTL = defaultTTL
        self.diskDirectoryName = diskDirectoryName
    }
    
    private enum Const {
        static let defaultMemoryCapacity: Int =  20 * 1024 * 1024   //20MB
        static let defaultDiskCapacity: Int =  100 * 1024 * 1024    //100MB
        static let defaultTTL: TimeInterval =  6 * 60 * 60 //6Hour
        static let defaultDirectoryName: String = "com.carrot.imagecache"
    }
}
