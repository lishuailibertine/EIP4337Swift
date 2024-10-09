//
//  EIP4337Error.swift
//  
//
//  Created by mathwallet on 2023/3/13.
//

import Foundation

public enum EIP4337Error: LocalizedError {
    case valueError(reason: String)
    case dataError
    case unknownError
    
    
    public var errorDescription: String? {
        switch self {
        case .valueError(let reason):
            return reason
        case .dataError:
            return "Data Error"
        case .unknownError:
            return "Unknown Error"
        }
    }
}
