//
//  BundlerProvider.swift
//  
//
//  Created by mathwallet on 2023/3/13.
//

import Foundation
import web3swift
import BigInt

public protocol BundlerProvider {
    var network: Networks? {get set}
    var url: URL {get}
    var session: URLSession {get}
}

public struct BundlerHttpProvider: BundlerProvider {
    public var network: Networks?
    public var url: URL
    public var session: URLSession = {() -> URLSession in
        let config = URLSessionConfiguration.default
        let urlSession = URLSession(configuration: config)
        return urlSession
    }()
    
    public init(url: URL, network: Networks) {
        self.url = url
        self.network = network
    }
}

extension BundlerHttpProvider {
    public func getChainId() async throws -> BigUInt {
        let request = BundlerAPIRequest.getNetwork
        return try await BundlerAPIRequest.sendRequest(with: self, for: request).result
    }
    
    public func supportedEntryPoints() async throws -> [EthereumAddress] {
        let request = BundlerAPIRequest.supportedEntryPoints
        let addresses: [String] = try await BundlerAPIRequest.sendRequest(with: self, for: request).result
        return addresses.map({ EthereumAddress($0)! })
    }
    
    public func sendUserOperation(_ userOperation: UserOperation, entryPoint: EthereumAddress) async throws -> Hash {
        let request = BundlerAPIRequest.sendUserOperation(userOperation, entryPoint)
        return try await BundlerAPIRequest.sendRequest(with: self, for: request).result
    }
    
    public func estimateGas(_ userOperation: UserOperation, entryPoint: EthereumAddress) async throws -> EstimateUserOperationGasResult {
        let request = BundlerAPIRequest.estimateGas(userOperation, entryPoint)
        return try await BundlerAPIRequest.sendRequest(with: self, for: request).result
    }
    
    public func getUserOperationByHash(_ hash: Hash) async throws -> UserOperationByHashResult {
        let request = BundlerAPIRequest.getUserOperationByHash(hash)
        return try await BundlerAPIRequest.sendRequest(with: self, for: request).result
    }
    
    public func getUserOperationReceipt(_ hash: Hash) async throws -> UserOperationReceiptResult {
        let request = BundlerAPIRequest.eth_getUserOperationReceipt(hash)
        return try await BundlerAPIRequest.sendRequest(with: self, for: request).result
    }
}
