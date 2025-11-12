//
//  ImageCacheConfiguration.swift
//  Carrot
//
//  Created by Jacob on 11/11/25.
//

import Foundation

/// 커스텀 이미지 캐시에 필요한 설정값
/// 환경별 메모리/디스크 한도, TTL
struct ImageCacheConfiguration {
    let memoryCapacity: Int
    let diskCapacity: Int
    let defaultTTL: TimeInterval
    let diskDirectoryName: String

    /// - Parameters:
    ///   - memoryCapacity: 메모리 LRU 캐시가 사용할 수 있는 최대 바이트 수
    ///   - diskCapacity: 디스크에 저장할 수 있는 최대 바이트 수
    ///   - defaultTTL: 별도 TTL을 넘기지 않았을 때 기본 만료 시간
    ///   - diskDirectoryName: Caches 디렉터리 하위의 저장 폴더명
    ///   - dateProvider: 테스트 편의를 위한 시계 추상화
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
