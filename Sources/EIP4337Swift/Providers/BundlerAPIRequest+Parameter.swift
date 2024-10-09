//
//  File.swift
//  
//
//  Created by mathwallet on 2023/3/13.
//

import Foundation
import web3swift

public struct BundlerAPIRequestBody: Encodable {
    var jsonrpc = "2.0"
    var id = Counter.increment()

    var method: String
    var params: [BundlerAPIRequestParameter]
}

public protocol BundlerAPIRequestParameterType: Encodable { }
extension String: BundlerAPIRequestParameterType { }

public enum BundlerAPIRequestParameter {
    case string(String)
    case userOperation(UserOperation)
}

extension BundlerAPIRequestParameter: Encodable {
    public func encode(to encoder: Encoder) throws {
        var enumContainer = encoder.singleValueContainer()
        /// force casting in this switch is safe because
        /// each `rawValue` forced to casts only in exact case which is runs based on `rawValue` type
        switch type(of: self.rawValue) {
        case is String.Type: try enumContainer.encode(rawValue as! String)
        case is UserOperation.Type: try enumContainer.encode(rawValue as! UserOperation)
            
        default: break /// can't be executed, coz possible `self.rawValue` types are strictly defined in it's implementation.`
        }
    }
}

extension BundlerAPIRequestParameter: RawRepresentable {
    public init?(rawValue: BundlerAPIRequestParameterType) {
        switch type(of: rawValue) {
        case is String.Type: self = .string(rawValue as! String)
        case is UserOperation.Type: self = .userOperation(rawValue as! UserOperation)
        default: return nil
        }
    }

    public var rawValue: BundlerAPIRequestParameterType {
        switch self {
        case let .string(value): return value
        case let .userOperation(value): return value
        }
    }
}
