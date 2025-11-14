//
//  DiskCacheRecord.swift
//  Carrot
//
//  Created by Jacob on 11/13/25.
//

import Foundation

struct DiskCacheRecord: Codable {
    let fileName: String            // 이름(해시)
    var fileSize: Int               // 사이즈
    var lastAccessDate: Date        // 마지막 접근 시각
    var accessCount: Int = 0        // 접근횟수
    var expirationDate: Date?       // 만료
}
