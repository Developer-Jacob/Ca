//
//  String+Extensions.swift
//  Carrot
//
//  Created by Jacob on 11/13/25.
//

import Foundation
import CryptoKit

extension String {
    var hashedSHA256: String {
        let digest = SHA256.hash(data: Data(self.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
