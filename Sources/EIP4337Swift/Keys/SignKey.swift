//
//  SignKey.swift
//  
//
//  Created by mathwallet on 2023/8/24.
//

import Foundation
import web3swift
import BigInt
import Secp256k1Swift
public struct SignKey {
    public var address: EthereumAddress
    public var mnemonics: String?
    public var privateKey: Data
    
    public func sign(_ op: inout UserOperation, entryPoint: EthereumAddress, chainId: BigUInt) throws {
        try op.sign(privateKey, entryPoint: entryPoint, chainId: chainId)
    }
    
    public func sign(_ message: Data, isHash: Bool = false) throws -> Data {
        let _hash = isHash ? message : Utilities.hashPersonalMessage(message)
        guard let hash = _hash else { throw EIP4337Error.dataError }
        
        let ( compressedSignature, _ ) = SECP256K1.signForRecovery(hash: hash, privateKey: privateKey)
        guard let sig = compressedSignature else { throw EIP4337Error.unknownError }
        return sig
    }
}

extension SignKey {
    public static func generateSignKey(forPath path: String = "m/44'/60'/0'/0/0", language: BIP39Language = .english) throws -> Self {
        guard let mnemonics = try BIP39.generateMnemonics(bitsOfEntropy: 128, language: language) else {
            throw EIP4337Error.dataError
        }
        return try SignKey.signKey(mnemonics, path: path, language: language)
    }
    
    public static func signKey(_ mnemonics: String, path: String = "m/44'/60'/0'/0/0", language: BIP39Language = .english) throws -> Self {
        guard let entropy = BIP39.mnemonicsToEntropy(mnemonics, language: language),
              let seed = BIP39.seedFromEntropy(entropy) else {
            throw EIP4337Error.valueError(reason: "Invalid mnemonics")
        }
        
        guard let node = HDNode(seed: seed), let treeNode = node.derive(path: path) else {
            throw EIP4337Error.valueError(reason: "Invalid mnemonics")
        }
        
        guard let privateKey = treeNode.privateKey else {
            throw EIP4337Error.valueError(reason: "Invalid mnemonics")
        }
        
        var key = try SignKey.signKey(privateKey)
        key.mnemonics = mnemonics
        return key
    }
    
    public static func signKey(_ privateKey: Data) throws -> Self {
        guard SECP256K1.verifyPrivateKey(privateKey: privateKey) else {
            throw EIP4337Error.valueError(reason: "Invalid PrivateKey")
        }
        
        guard let publicKey = Utilities.privateToPublic(privateKey) else {
            throw EIP4337Error.valueError(reason: "Invalid PrivateKey")
        }
        
        guard let address = Utilities.publicToAddress(publicKey) else {
            throw EIP4337Error.valueError(reason: "Invalid PrivateKey")
        }
        
        return SignKey(address: address, mnemonics: nil, privateKey: privateKey)
    }
}
