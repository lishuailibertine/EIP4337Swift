//
//  EIP4337Tests.swift
//
//
//  Created by mathwallet on 2023/3/13.
//

import XCTest
import web3swift
import BigInt

@testable import EIP4337Swift

final class EIP4337Tests: XCTestCase {
    
    static let url = URL(string: "https://polygon-mumbai.blockpi.network/v1/rpc/508e51965dbaccae68c3bef8306256040fd0a967")!
    static let network = Networks.Custom(networkID: BigUInt(80001))
    static let entryPoint = EthereumAddress("0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789")!
    
    // 0x4D4E47F4A0556FEc5C2413AD47D58F46336f63D1
    static let privateKey = Data(hex: "d5158369a29c1d11dfccee8d77b9fb4dc113746e3fdf0e242af0a315334b7475")
    static let ownerAddress = Utilities.publicToAddress(Utilities.privateToPublic(privateKey)!)!
    static let factoryAddress = EthereumAddress("0x091E93934183C28Cb981DC39451a4Ae0393f2c68")!
    static let aaAddress = SimpleAccountFactory(factoryAddress).computeAccountAddress(owner: ownerAddress)
    
    func testContractAccountExample() throws {
        XCTAssert(Self.aaAddress == EthereumAddress("0xDb4c934675Ddeb4981F9756cd247d0C50692d535")!)
    }
    
    func testChainIdExample() async throws {
        let bundlerProvider = BundlerHttpProvider(url: Self.url, network: Self.network)
        let chainId = try await bundlerProvider.getChainId()
        XCTAssert(chainId == BigUInt(80001))
    }
    
    func testSupportedEntryPointsExample() async throws {
        let bundlerProvider = BundlerHttpProvider(url: Self.url, network: Self.network)
        let entryPoints = try await bundlerProvider.supportedEntryPoints()
        debugPrint(entryPoints)
        XCTAssert(entryPoints.contains(Self.entryPoint))
    }
    
    func testEstimateUserOperationGasExample() async throws {
        let web3 = try await Web3.new(Self.url, network: Self.network)
        let bundlerProvider = BundlerHttpProvider(url: Self.url, network: Self.network)
        
        let simpleAccount = SimpleAccount(web3: web3, ownerAddress: Self.ownerAddress, factoryAddress: Self.factoryAddress)
        var op = try await simpleAccount.transfer(
            to: EthereumAddress("0x306Bb8081C7dD356eA951795Ce4072e6e4bFdC32")!,
            value: Utilities.parseToBigUInt("0.0001", decimals: 18)!)

        op.maxFeePerGas = BigUInt(Utilities.parseToBigUInt("1", units: .gwei)!)
        op.maxPriorityFeePerGas = BigUInt(Utilities.parseToBigUInt("1", units: .gwei)!)
        op.signature = Data(hex: "0x6830f7919b07d49fe97aea17baffda96be0ab949d098da38d311ef71ca11767d558bef9d909a71e4fcae753d786635783d2af32df344ebe3835ac42a85ae0fe41c")
        let gasResult = try await bundlerProvider.estimateGas(op, entryPoint: Self.entryPoint)
        debugPrint(gasResult)
//        op.callGasLimit = gasResult.callGasLimit
//        op.verificationGasLimit = gasResult.verificationGas
//        op.preVerificationGas = gasResult.preVerificationGas
    }
    
    func testCreateUserOpExample() async throws {
        let web3 = try await Web3.new(Self.url, network: Self.network)
        let simpleAccount = SimpleAccount(web3: web3, ownerAddress: Self.ownerAddress, factoryAddress: Self.factoryAddress)
        
        let op = try await simpleAccount.execute(
            dest: EthereumAddress(from: "0x306Bb8081C7dD356eA951795Ce4072e6e4bFdC32")!,
            value: Utilities.parseToBigUInt("0.0001", decimals: 18)!,
            func: Data()
        )
        
        XCTAssert(op.initCode == Data(hex: "0x"))
        XCTAssert(op.callData == Data(hex: "0xb61d27f6000000000000000000000000306bb8081c7dd356ea951795ce4072e6e4bfdc3200000000000000000000000000000000000000000000000000005af3107a400000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000"))
    }
    
    func testSendUserOpExample() async throws {
        debugPrint(Self.ownerAddress.address)
        let web3 = try await Web3.new(Self.url, network: Self.network)
        let bundlerProvider = BundlerHttpProvider(url: Self.url, network: Self.network)
        
        // SimpleAccount
        let simpleAccount = SimpleAccount(web3: web3, ownerAddress: Self.ownerAddress, factoryAddress: Self.factoryAddress)
        
        var op = try await simpleAccount.transfer(
            to: EthereumAddress(from: "0x306Bb8081C7dD356eA951795Ce4072e6e4bFdC32")!,
            value:  Utilities.parseToBigUInt("0.0001", decimals: 18)!
        )
        
        /*
        var op = try await simpleAccount.transferERC20(
            EthereumAddress(from: "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6")!,
            to: EthereumAddress(from: "0x306Bb8081C7dD356eA951795Ce4072e6e4bFdC32")!,
            value: Utilities.parseToBigUInt("0.0001", decimals: 18)!
        )
         */
        
        // CallGasLimit
//        var callTx = CodableTransaction(type: .eip1559, to: op.sender, chainID: Self.network.chainID, data: op.callData)
//        callTx.from = Self.entryPoint
//        let callGasLimit = try await web3.eth.estimateGas(for: callTx)
//        
//        debugPrint("callGasLimit \(callGasLimit.description)")
        
        // MaxFeePerGas & MaxPriorityFeePerGas
        let oracle = Oracle(web3.provider)
        let (baseFees, tipFees) = await oracle.bothFeesPercentiles() ?? ([],[])
        let maxFeePerGas = (baseFees.first ?? BigUInt(0)) + (tipFees.first ?? BigUInt(0))
        let maxPriorityFeePerGas = (tipFees.first ?? BigUInt(0))
        
        op.maxFeePerGas = maxFeePerGas
        op.maxPriorityFeePerGas = maxPriorityFeePerGas
        
        var dummyUserOp = op
        dummyUserOp.signature = Data(hex: "0x6830f7919b07d49fe97aea17baffda96be0ab949d098da38d311ef71ca11767d558bef9d909a71e4fcae753d786635783d2af32df344ebe3835ac42a85ae0fe41c")
        let gasResult = try await bundlerProvider.estimateGas(dummyUserOp, entryPoint: Self.entryPoint)
        
        // Gas
        op.callGasLimit = gasResult.callGasLimit
        op.verificationGasLimit = gasResult.verificationGas
        op.preVerificationGas = gasResult.preVerificationGas
        
        /*
         "0x4D4E47F4A0556FEc5C2413AD47D58F46336f63D1"
         "callGasLimit 33100"
         "maxFeePerGas 14.806635144"
         "maxPriorityFeePerGas 14.806635128"
         "verificationGasLimit 39647"
         "preVerificationGas 49133"
         "(callGasLimit + verificationGasLimit) * maxFeePerGas 0.0010771382"
         "0xae4d7d984b52db30357cd683ff7680c0a5eb904f76ae2b8fa16f3593b30ffcdb"
         
         */
        
        debugPrint("callGasLimit \(Utilities.formatToPrecision(op.callGasLimit, units: .wei, formattingDecimals: 10))")
        debugPrint("maxFeePerGas \(Utilities.formatToPrecision(op.maxFeePerGas, units: .gwei, formattingDecimals: 10))")
        debugPrint("maxPriorityFeePerGas \(Utilities.formatToPrecision(op.maxPriorityFeePerGas, units: .gwei, formattingDecimals: 10))")
        debugPrint("verificationGasLimit \(Utilities.formatToPrecision(op.verificationGasLimit, units: .wei, formattingDecimals: 10))")
        debugPrint("preVerificationGas \(Utilities.formatToPrecision(op.preVerificationGas, units: .wei, formattingDecimals: 10))")
        
        debugPrint("(callGasLimit + verificationGasLimit + preVerificationGas) * maxFeePerGas \(Utilities.formatToPrecision((op.callGasLimit + op.verificationGasLimit + op.preVerificationGas) * op.maxFeePerGas, units: .ether, formattingDecimals: 10))")
        // Sign
        try op.sign(Self.privateKey, entryPoint: Self.entryPoint, chainId: Self.network.chainID)
        // Send
        let hash = try await bundlerProvider.sendUserOperation(op, entryPoint: Self.entryPoint)
        debugPrint(hash)
    }
    
    func testGetUserOpByHashExample() async throws {
        let bundlerProvider = BundlerHttpProvider(url: Self.url, network: Self.network)
        let userOpHash = "0x2ee75abcf48ee1429aaeac495cfa236fba8270e06dc5cc1be397d36885e1aef3"
        let result = try await bundlerProvider.getUserOperationByHash(userOpHash)
        debugPrint(result)
        XCTAssert(result.userOperation.getUserOpHash(entryPoint: Self.entryPoint, chainId: Self.network.chainID)?.toHexString().addHexPrefix() == userOpHash)
    }
    
    func testGetUserOpReceiptExample() async throws {
        let bundlerProvider = BundlerHttpProvider(url: Self.url, network: Self.network)
        let userOpHash = "0xae4d7d984b52db30357cd683ff7680c0a5eb904f76ae2b8fa16f3593b30ffcdb"
        let result = try await bundlerProvider.getUserOperationReceipt(userOpHash)
        debugPrint(result)
        XCTAssert(result.userOpHash == userOpHash)
    }

}
