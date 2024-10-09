//
//  SimpleAccount.swift
//  
//
//  Created by mathwallet on 2023/3/10.
//

import Foundation
import web3swift
import BigInt

public struct SimpleAccount {
    public let ownerAddress: EthereumAddress
    
    private let factory: SimpleAccountFactory
    private let web3: Web3
    
    public var address: EthereumAddress {
        return factory.computeAccountAddress(owner: ownerAddress, salt: BigUInt(0))
    }
    
    private var contract: Web3.Contract {
        return web3.contract(SimpleAccount.ABI, at: address)!
    }
    
    public init(web3: Web3, ownerAddress: EthereumAddress, factoryAddress: EthereumAddress) {
        self.web3 = web3
        self.ownerAddress = ownerAddress
        self.factory = SimpleAccountFactory(factoryAddress)
    }
    
    public func getNonce() async throws -> BigUInt {
        let readTX = contract.createReadOperation("getNonce")!
        let response = try await readTX.callContractMethod()
        let nonce = response["0"] as? BigUInt
        return nonce ?? BigUInt(0)
    }
    
    private func initCode() async throws -> Data {
        let code = try await web3.eth.code(for: address)
        if code.stripHexPrefix().count > 0 {
            return Data()
        } else {
            return try self.factory.address.addressData + self.factory.createAccount(owner: self.ownerAddress)
        }
    }
    
    public func execute(dest: EthereumAddress, value: BigUInt, func callData: Data = Data()) async throws -> UserOperation {
        let contract = try EthereumContract(Self.ABI, at: self.address)
        guard let callData = contract.method("execute", parameters: [dest, value, callData], extraData: nil) else {
            throw EIP4337Error.unknownError
        }
        
        let nonce = try await getNonce()
        let initCode = try await self.initCode()
        
        return UserOperation(sender: address, nonce: nonce, initCode: initCode, callData: callData)
    }
    
    public func executeBatch(dest: [EthereumAddress], func callData: [Data]) async throws -> UserOperation {
        guard dest.count == callData.count else {
            throw EIP4337Error.unknownError
        }
        let contract = try EthereumContract(Self.ABI, at: self.address)
        guard let callData = contract.method("executeBatch", parameters: [dest, callData], extraData: nil) else {
            throw EIP4337Error.unknownError
        }
        
        let nonce = try await getNonce()
        let initCode = try await self.initCode()
        
        return UserOperation(sender: address, nonce: nonce, initCode: initCode, callData: callData)
    }
}

extension SimpleAccount {
    public func transfer(to: EthereumAddress, value: BigUInt) async throws -> UserOperation {
        return try await self.execute(dest: to, value: value)
    }
    
    public func transferERC20(_ token: EthereumAddress, to: EthereumAddress, value: BigUInt) async throws -> UserOperation {
        let contract = try EthereumContract(Web3.Utils.erc20ABI, at: token)
        guard let callData = contract.method("transfer", parameters: [to, value], extraData: nil) else {
            throw EIP4337Error.unknownError
        }
        return try await self.execute(dest: token, value: BigUInt(0), func: callData)
    }
    
    public func transferERC721(_ token: EthereumAddress, tokenId: BigUInt, to: EthereumAddress) async throws -> UserOperation {
        let contract = try EthereumContract(Web3.Utils.erc721ABI, at: token)
        guard let callData = contract.method("safeTransferFrom", parameters: [self.address, to, tokenId, Data()], extraData: nil) else {
            throw EIP4337Error.unknownError
        }
        return try await self.execute(dest: token, value: BigUInt(0), func: callData)
    }
    
    public func transferERC1155(_ token: EthereumAddress, tokenId: BigUInt, to: EthereumAddress, value: BigUInt = BigUInt(1)) async throws -> UserOperation {
        let contract = try EthereumContract(Web3.Utils.erc1155ABI, at: token)
        guard let callData = contract.method("safeTransferFrom", parameters: [self.address, to, tokenId, value, Data()], extraData: nil) else {
            throw EIP4337Error.unknownError
        }
        return try await self.execute(dest: token, value: BigUInt(0), func: callData)
    }
}

extension SimpleAccount {
    static let ABI: String = """
        [{"inputs":[{"internalType":"contract IEntryPoint","name":"anEntryPoint","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"previousAdmin","type":"address"},{"indexed":false,"internalType":"address","name":"newAdmin","type":"address"}],"name":"AdminChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"beacon","type":"address"}],"name":"BeaconUpgraded","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint8","name":"version","type":"uint8"}],"name":"Initialized","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"contract IEntryPoint","name":"entryPoint","type":"address"},{"indexed":true,"internalType":"address","name":"owner","type":"address"}],"name":"SimpleAccountInitialized","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"implementation","type":"address"}],"name":"Upgraded","type":"event"},{"inputs":[],"name":"addDeposit","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"entryPoint","outputs":[{"internalType":"contract IEntryPoint","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"dest","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"bytes","name":"func","type":"bytes"}],"name":"execute","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address[]","name":"dest","type":"address[]"},{"internalType":"uint256[]","name":"value","type":"uint256[]"},{"internalType":"bytes[]","name":"func","type":"bytes[]"}],"name":"executeBatch","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"getDeposit","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getNonce","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"anOwner","type":"address"}],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"uint256[]","name":"","type":"uint256[]"},{"internalType":"uint256[]","name":"","type":"uint256[]"},{"internalType":"bytes","name":"","type":"bytes"}],"name":"onERC1155BatchReceived","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"bytes","name":"","type":"bytes"}],"name":"onERC1155Received","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"bytes","name":"","type":"bytes"}],"name":"onERC721Received","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"proxiableUUID","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes4","name":"interfaceId","type":"bytes4"}],"name":"supportsInterface","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"bytes","name":"","type":"bytes"},{"internalType":"bytes","name":"","type":"bytes"}],"name":"tokensReceived","outputs":[],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"newImplementation","type":"address"}],"name":"upgradeTo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newImplementation","type":"address"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"upgradeToAndCall","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"components":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"uint256","name":"nonce","type":"uint256"},{"internalType":"bytes","name":"initCode","type":"bytes"},{"internalType":"bytes","name":"callData","type":"bytes"},{"internalType":"uint256","name":"callGasLimit","type":"uint256"},{"internalType":"uint256","name":"verificationGasLimit","type":"uint256"},{"internalType":"uint256","name":"preVerificationGas","type":"uint256"},{"internalType":"uint256","name":"maxFeePerGas","type":"uint256"},{"internalType":"uint256","name":"maxPriorityFeePerGas","type":"uint256"},{"internalType":"bytes","name":"paymasterAndData","type":"bytes"},{"internalType":"bytes","name":"signature","type":"bytes"}],"internalType":"struct UserOperation","name":"userOp","type":"tuple"},{"internalType":"bytes32","name":"userOpHash","type":"bytes32"},{"internalType":"uint256","name":"missingAccountFunds","type":"uint256"}],"name":"validateUserOp","outputs":[{"internalType":"uint256","name":"validationData","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address payable","name":"withdrawAddress","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"withdrawDepositTo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"stateMutability":"payable","type":"receive"}]
    """
}
