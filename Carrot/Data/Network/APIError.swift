//
//  APIError.swift
//  Carrot
//
//  Created by Jacob on 11/10/25.
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidRequest
    case invalidResponse
    case httpStatus(Int)
    case decoding
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidRequest: return "잘못된 요청입니다."
        case .invalidResponse: return "잘못된 응답 형식입니다."
        case .httpStatus(let code): return "서버 오류 (status: \(code))"
        case .decoding: return "데이터 해석에 실패했습니다."
        case .server(let message): return message
        }
    }
}
