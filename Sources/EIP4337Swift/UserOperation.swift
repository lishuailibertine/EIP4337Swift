//
//  UserOperation.swift
//  
//
//  Created by mathwallet on 2023/3/10.
//

import BigInt
import web3swift
import Secp256k1Swift
import Foundation

public struct UserOperation {
    public var sender: EthereumAddress
    public var nonce: BigUInt = BigUInt(0)
    public var initCode: Data = Data()
    public var callData: Data
    public var callGasLimit: BigUInt = BigUInt(0)
    public var verificationGasLimit: BigUInt = BigUInt(0)
    public var preVerificationGas: BigUInt = BigUInt(0)
    public var maxFeePerGas: BigUInt = BigUInt(0)
    public var maxPriorityFeePerGas: BigUInt = BigUInt(0)
    public var paymasterAndData: Data = Data()
    public var signature: Data = Data()
    
    public init(sender: EthereumAddress,
                nonce: BigUInt = BigUInt(0),
                initCode: Data = Data(),
                callData: Data,
                callGasLimit: BigUInt = BigUInt(0),
                verificationGasLimit: BigUInt = BigUInt(0),
                preVerificationGas: BigUInt = BigUInt(0),
                maxFeePerGas: BigUInt = BigUInt(0),
                maxPriorityFeePerGas: BigUInt = BigUInt(0),
                paymasterAndData: Data = Data()
    ) {
        self.sender = sender
        self.nonce = nonce
        self.initCode = initCode
        self.callData = callData
        self.callGasLimit = callGasLimit
        self.verificationGasLimit = verificationGasLimit
        self.preVerificationGas = preVerificationGas
        self.maxFeePerGas = maxFeePerGas
        self.maxPriorityFeePerGas = maxPriorityFeePerGas
        self.paymasterAndData = paymasterAndData
    }
    
    public func pack(_ forSignature: Bool = true) -> Data? {
        let types: [ABI.Element.ParameterType]
        let values: [Any]
        if forSignature {
            types = [
                .address,
                .uint(bits: 256),
                .bytes(length: 32),
                .bytes(length: 32),
                .uint(bits: 256),
                .uint(bits: 256),
                .uint(bits: 256),
                .uint(bits: 256),
                .uint(bits: 256),
                .bytes(length: 32)
            ]
            values =  [
                sender,
                nonce,
                initCode.sha3(.keccak256),
                callData.sha3(.keccak256),
                callGasLimit,
                verificationGasLimit,
                preVerificationGas,
                maxFeePerGas,
                maxPriorityFeePerGas,
                paymasterAndData.sha3(.keccak256)
            ]
        } else {
            types = [
                .address,
                .uint(bits: 256),
                .dynamicBytes,
                .dynamicBytes,
                .uint(bits: 256),
                .uint(bits: 256),
                .uint(bits: 256),
                .uint(bits: 256),
                .uint(bits: 256),
                .dynamicBytes,
                .dynamicBytes
            ]
            values =  [
                sender,
                nonce,
                initCode,
                callData,
                callGasLimit,
                verificationGasLimit,
                preVerificationGas,
                maxFeePerGas,
                maxPriorityFeePerGas,
                paymasterAndData,
                signature
            ]
        }
        guard let encoded = ABIEncoder.encode(types: types, values: values) else { return nil }
        return encoded
    }
    
    public func getUserOpHash(entryPoint: EthereumAddress, chainId: BigUInt) -> Data? {
        guard let opPacked = pack(true) else { return nil }
        return ABIEncoder.encode(types: [
                                    .bytes(length: 32),
                                    .address,
                                    .uint(bits: 256)
                                 ],
                                 values: [
                                    opPacked.sha3(.keccak256),
                                    entryPoint,
                                    chainId
                                 ]
        )?.sha3(.keccak256)
    }
    
    public mutating func sign(_ privateKey: Data, entryPoint: EthereumAddress, chainId: BigUInt) throws {
        guard let opHash = self.getUserOpHash(entryPoint: entryPoint, chainId: chainId) else { throw EIP4337Error.unknownError }
        guard let hash = Utilities.hashPersonalMessage(opHash) else { throw EIP4337Error.unknownError }
        
        let ( compressedSignature, _ ) = SECP256K1.signForRecovery(hash: hash, privateKey: privateKey)
        guard let sig = compressedSignature else { throw EIP4337Error.unknownError }
        
        self.signature = sig
    }
}

extension UserOperation: CustomStringConvertible {
    public var description: String {
        return """
            [UserOperation]:
                sender: \(sender.address)
                nonce: \(nonce.description)
                initCode: \(initCode.toHexString().addHexPrefix())
                callData: \(callData.toHexString().addHexPrefix())
                callGasLimit: \(callGasLimit.description)
                verificationGasLimit: \(verificationGasLimit.description)
                preVerificationGas: \(preVerificationGas.description)
                maxFeePerGas: \(maxFeePerGas.description)
                maxPriorityFeePerGas: \(maxPriorityFeePerGas.description)
                paymasterAndData: \(paymasterAndData.toHexString().addHexPrefix())
                signature: \(signature.toHexString().addHexPrefix())
        """
    }
}

extension UserOperation: Codable {
    enum CodingKeys: String, CodingKey {
        case sender
        case nonce
        case initCode
        case callData
        case callGasLimit
        case verificationGasLimit
        case preVerificationGas
        case maxFeePerGas
        case maxPriorityFeePerGas
        case paymasterAndData
        case signature
    }
    
    public func encode(to encoder: Encoder) throws {
        var containier = encoder.container(keyedBy: CodingKeys.self)
        try containier.encode(sender.address, forKey: .sender)
        try containier.encode(nonce.hexString, forKey: .nonce)
        try containier.encode(initCode.toHexString().addHexPrefix(), forKey: .initCode)
        try containier.encode(callData.toHexString().addHexPrefix(), forKey: .callData)
        try containier.encode(callGasLimit.hexString, forKey: .callGasLimit)
        try containier.encode(verificationGasLimit.hexString, forKey: .verificationGasLimit)
        try containier.encode(preVerificationGas.hexString, forKey: .preVerificationGas)
        try containier.encode(maxFeePerGas.hexString, forKey: .maxFeePerGas)
        try containier.encode(maxPriorityFeePerGas.hexString, forKey: .maxPriorityFeePerGas)
        try containier.encode(paymasterAndData.toHexString().addHexPrefix(), forKey: .paymasterAndData)
        try containier.encode(signature.toHexString().addHexPrefix(), forKey: .signature)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        guard let senderString = try container.decodeIfPresent(String.self, forKey: .sender), let sender = EthereumAddress(senderString) else {
            throw EIP4337Error.dataError
        }
        
        self.sender = sender
        self.nonce = try container.decodeHex(BigUInt.self, forKey: .nonce)
        self.initCode = try container.decodeHex(Data.self, forKey: .initCode)
        self.callData = try container.decodeHex(Data.self, forKey: .callData)
        self.callGasLimit = try container.decodeHex(BigUInt.self, forKey: .callGasLimit)
        self.verificationGasLimit = try container.decodeHex(BigUInt.self, forKey: .verificationGasLimit)
        self.preVerificationGas = try container.decodeHex(BigUInt.self, forKey: .preVerificationGas)
        self.maxFeePerGas = try container.decodeHex(BigUInt.self, forKey: .maxFeePerGas)
        self.maxPriorityFeePerGas = try container.decodeHex(BigUInt.self, forKey: .maxPriorityFeePerGas)
        self.paymasterAndData = try container.decodeHex(Data.self, forKey: .paymasterAndData)
        self.signature = try container.decodeHex(Data.self, forKey: .signature)
    }
}

extension UserOperation: BundlerAPIRequestParameterType { }
