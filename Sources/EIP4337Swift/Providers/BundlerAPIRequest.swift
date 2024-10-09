//
//  BundlerAPIRequest.swift
//  
//
//  Created by mathwallet on 2023/3/13.
//
import Foundation
import web3swift
public enum BundlerAPIRequest {
    /// Get current network
    case getNetwork
    
    /// Supported EntryPoints
    case supportedEntryPoints
    
    /// Send UserOperation
    /// - Parameters:
    ///     - UserOperation:  op to be sent into chain
    ///     - EthereumAddress:  EntryPoint address
    case sendUserOperation(UserOperation, EthereumAddress)
    
    /// Estimate Gas
    /// - Parameters:
    ///     - UserOperation:  op to be sent into chain
    ///     - EthereumAddress:  EntryPoint address
    case estimateGas(UserOperation, EthereumAddress)
    
    /// Get UserOperation By Hash
    /// - Parameters:
    ///     - Hash:  op hash
    case getUserOperationByHash(Hash)
    
    /// Get UserOperation Receipt
    /// - Parameters:
    ///     - Hash:  op hash
    case eth_getUserOperationReceipt(Hash)
}

extension BundlerAPIRequest {
    public static func sendRequest<Result>(with provider: BundlerProvider, for call: BundlerAPIRequest) async throws -> APIResponse<Result> {
        let request = setupRequest(for: call, with: provider)
        return try await BundlerAPIRequest.send(uRLRequest: request, with: provider.session)
    }

    static func setupRequest(for call: BundlerAPIRequest, with provider: BundlerProvider) -> URLRequest {
        var urlRequest = URLRequest(url: provider.url, cachePolicy: .reloadIgnoringCacheData)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.httpMethod = call.method.rawValue
        urlRequest.httpBody = call.encodedBody
//        debugPrint(String(data: call.encodedBody, encoding: .utf8)!)
        return urlRequest
    }

    public static func send<Result>(uRLRequest: URLRequest, with session: URLSession) async throws -> APIResponse<Result> {
        let (data, _) = try await session.data(for: uRLRequest)
//        debugPrint(String(data: data, encoding: .utf8)!)
        if let error = (try? JSONDecoder().decode(JsonRpcErrorObject.self, from: data))?.error {
            guard let parsedErrorCode = error.parsedErrorCode else {
                throw Web3Error.nodeError(desc: "\(error.message)\nError code: \(error.code)")
            }
            let description = "\(parsedErrorCode.errorName). Error code: \(error.code). \(error.message)"
            switch parsedErrorCode {
            case .parseError, .invalidParams:
                throw Web3Error.inputError(desc: description)
            case .methodNotFound, .invalidRequest:
                throw Web3Error.processingError(desc: description)
            case .internalError, .serverError:
                throw Web3Error.nodeError(desc: description)
            }
        }

        /// This bit of code is purposed to work with literal types that comes in ``Response`` in hexString type.
        /// Currently it's just `Data` and any kind of Integers `(U)Int`, `Big(U)Int`.
        if let LiteralType = Result.self as? LiteralInitiableFromString.Type {
            guard let responseAsString = try? JSONDecoder().decode(APIResponse<String>.self, from: data) else { throw Web3Error.dataError }
            guard let literalValue = LiteralType.init(from: responseAsString.result) else { throw Web3Error.dataError }
            /// `literalValue` conforms `LiteralInitiableFromString`, that conforming to an `APIResponseType` type, so it's never fails.
            guard let result = literalValue as? Result else { throw Web3Error.typeError }
            return APIResponse(id: responseAsString.id, jsonrpc: responseAsString.jsonrpc, result: result)
        }
        return try JSONDecoder().decode(APIResponse<Result>.self, from: data)
    }
}

extension BundlerAPIRequest {
    public var method: REST {
         .POST
    }

    public var encodedBody: Data {
        let request = BundlerAPIRequestBody(method: call, params: parameters)
        return try! JSONEncoder().encode(request)
    }
    
    public var parameters: [BundlerAPIRequestParameter] {
        switch self {
        case .getNetwork:
            return []
        case .supportedEntryPoints:
            return []
        case let .estimateGas(userOperation, entryPoint):
            return [.userOperation(userOperation), .string(entryPoint.address)]
        case let .sendUserOperation(userOperation, entryPoint):
            return [.userOperation(userOperation), .string(entryPoint.address)]
        case let .getUserOperationByHash(hash):
            return [.string(hash)]
        case let .eth_getUserOperationReceipt(hash):
            return [.string(hash)]
        }
    }
    
    public var call: String {
        switch self {
        case .getNetwork: return "eth_chainId"
        case .supportedEntryPoints: return "eth_supportedEntryPoints"
        case .estimateGas: return "eth_estimateUserOperationGas"
        case .sendUserOperation: return "eth_sendUserOperation"
        case .getUserOperationByHash: return "eth_getUserOperationByHash"
        case .eth_getUserOperationReceipt: return "eth_getUserOperationReceipt"
        }
    }
}
