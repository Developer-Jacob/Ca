//
//  DiskCacheManifest.swift
//  Carrot
//
//  Created by Jacob on 11/13/25.
//

struct DiskCacheManifest: Codable {
    var totalSize: Int  // 캐시 전체 사이즈
    var records: [String: DiskCacheRecord]  //URL: 캐시레코드

    static func empty() -> DiskCacheManifest {
        DiskCacheManifest(totalSize: 0, records: [:])
    }
}
