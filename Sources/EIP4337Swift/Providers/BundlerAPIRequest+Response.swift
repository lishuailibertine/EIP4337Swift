//
//  BundlerAPIResponseType.swift
//  
//
//  Created by mathwallet on 2023/3/13.
//

import Foundation
import web3swift
import BigInt

public struct EstimateUserOperationGasResult: Decodable, APIResultType {
    public var preVerificationGas: BigUInt
    public var verificationGas: BigUInt
    public var callGasLimit: BigUInt
    
    enum CodingKeys: String, CodingKey {
        case preVerificationGas
        case verificationGas
        case callGasLimit
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let _preVerificationGas = try? container.decode(Int.self, forKey: .preVerificationGas) {
            self.preVerificationGas = BigUInt(_preVerificationGas)
        } else {
            self.preVerificationGas = try BigUInt(container.decode(String.self, forKey: .preVerificationGas).stripHexPrefix(), radix: 16) ?? BigUInt(0)
        }
        if let _verificationGas = try? container.decode(Int.self, forKey: .verificationGas) {
            self.verificationGas = BigUInt(_verificationGas)
        } else {
            self.verificationGas = try BigUInt(container.decode(String.self, forKey: .verificationGas).stripHexPrefix(), radix: 16) ?? BigUInt(0)
        }
        if let gasLimit = try? container.decode(Int.self, forKey: .callGasLimit) {
            self.callGasLimit = BigUInt(gasLimit)
        } else {
            self.callGasLimit = try BigUInt(container.decode(String.self, forKey: .callGasLimit).stripHexPrefix(), radix: 16) ?? BigUInt(0)
        }
    }
}

public struct UserOperationByHashResult: Decodable, APIResultType  {
    public var userOperation: UserOperation
    public var entryPoint: EthereumAddress
    public var blockNumber: BigUInt
    public var blockHash: Hash
    public var transactionHash: TransactionHash
    
    enum CodingKeys: CodingKey {
        case userOperation
        case entryPoint
        case blockNumber
        case blockHash
        case transactionHash
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let entryPointString = try container.decodeIfPresent(String.self, forKey: .entryPoint), let entryPoint = EthereumAddress(entryPointString) else {
            throw EIP4337Error.dataError
        }
        
        self.userOperation = try container.decode(UserOperation.self, forKey: .userOperation)
        self.entryPoint = entryPoint
        self.blockNumber = try BigUInt(container.decode(Int64.self, forKey: .blockNumber))
        self.blockHash = try container.decode(Hash.self, forKey: .blockHash)
        self.transactionHash = try container.decode(TransactionHash.self, forKey: .transactionHash)
    }
}

public struct UserOperationReceiptResult: Decodable, APIResultType  {
    public var userOpHash: Hash
    public var sender: EthereumAddress
    public var paymaster: EthereumAddress?
    public var nonce: BigUInt
    public var success: Bool
    public var actualGasCost: BigUInt
    public var actualGasUsed: BigUInt
    public var receipt: TransactionReceipt

    enum CodingKeys: CodingKey {
        case userOpHash
        case sender
        case paymaster
        case nonce
        case success
        case actualGasCost
        case actualGasUsed
        case receipt
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        guard let senderString = try container.decodeIfPresent(String.self, forKey: .sender), let sender = EthereumAddress(senderString) else {
            throw EIP4337Error.dataError
        }
        
        self.userOpHash = try container.decode(Hash.self, forKey: .userOpHash)
        self.sender = sender
        if let paymasterString = try container.decodeIfPresent(String.self, forKey: .paymaster), let paymaster = EthereumAddress(paymasterString) {
            self.paymaster = paymaster
        }
        self.nonce = try container.decodeHex(BigUInt.self, forKey: .nonce)
        self.success = try container.decode(Bool.self, forKey: .success)
        self.actualGasCost = try container.decodeHex(BigUInt.self, forKey: .actualGasCost)
        self.actualGasUsed = try container.decodeHex(BigUInt.self, forKey: .actualGasUsed)
        self.receipt = try container.decode(TransactionReceipt.self, forKey: .receipt)
    }
}

