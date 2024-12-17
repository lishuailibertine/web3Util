//
//  EthereumPublicKey.swift
//  Web3
//
//  Created by Koray Koska on 07.02.18.
//  Copyright © 2018 Boilertalk. All rights reserved.
//

import Foundation
import CSecp256k1
import CryptoSwift
import BigInt
public final class EthereumPublicKey {

    // MARK: - Properties

    /// The raw public key bytes
    public let rawPublicKey: Bytes

    /// True iff ctx should not be freed on deinit
    private let ctxSelfManaged: Bool

    /// Internal context for secp256k1 library calls
    private let ctx: OpaquePointer


    public init(message: Bytes, v: BigUInt, r: BigUInt, s: BigUInt, ctx: OpaquePointer? = nil) throws {
        // Create context
        let finalCtx: OpaquePointer
        if let ctx = ctx {
            finalCtx = ctx
            self.ctxSelfManaged = true
        } else {
            let ctx = try secp256k1_default_ctx_create(errorThrowable: Error.internalError)
            finalCtx = ctx
            self.ctxSelfManaged = false
        }
        self.ctx = finalCtx

        // Create raw signature array
        var rawSig = Bytes()
        var r = r.makeBytes().trimLeadingZeros()
        var s = s.makeBytes().trimLeadingZeros()

        guard r.count <= 32 && s.count <= 32 else {
            throw Error.signatureMalformed
        }
        guard let vUInt = v.makeBytes().bigEndianUInt, vUInt <= Int32.max else {
            throw Error.signatureMalformed
        }
        let v = Int32(vUInt)

        for _ in 0..<(32 - r.count) {
            r.insert(0, at: 0)
        }
        for _ in 0..<(32 - s.count) {
            s.insert(0, at: 0)
        }

        rawSig.append(contentsOf: r)
        rawSig.append(contentsOf: s)

        // Parse recoverable signature
        guard let recsig = malloc(MemoryLayout<secp256k1_ecdsa_recoverable_signature>.size)?.assumingMemoryBound(to: secp256k1_ecdsa_recoverable_signature.self) else {
            throw Error.internalError
        }
        defer {
            free(recsig)
        }
        guard secp256k1_ecdsa_recoverable_signature_parse_compact(finalCtx, recsig, &rawSig, v) == 1 else {
            throw Error.signatureMalformed
        }

        // Recover public key
        guard let pubkey = malloc(MemoryLayout<secp256k1_pubkey>.size)?.assumingMemoryBound(to: secp256k1_pubkey.self) else {
            throw Error.internalError
        }
        defer {
            free(pubkey)
        }
        var hash = SHA3(variant: .keccak256).calculate(for: message)
        guard hash.count == 32 else {
            throw Error.internalError
        }
        guard secp256k1_ecdsa_recover(finalCtx, pubkey, recsig, &hash) == 1 else {
            throw Error.signatureMalformed
        }

        // Generate uncompressed public key bytes
        var rawPubKey = Bytes(repeating: 0, count: 65)
        var outputlen = 65
        guard secp256k1_ec_pubkey_serialize(finalCtx, &rawPubKey, &outputlen, pubkey, UInt32(SECP256K1_EC_UNCOMPRESSED)) == 1 else {
            throw Error.internalError
        }

        rawPubKey.remove(at: 0)
        self.rawPublicKey = rawPubKey
    }

    /**
     * Returns this public key serialized as a hex string.
     */
    public func hex() -> String {
        var h = "0x"
        for b in rawPublicKey {
            h += String(format: "%02x", b)
        }

        return h
    }

    // MARK: - Errors

    public enum Error: Swift.Error {

        case internalError
        case keyMalformed
        case signatureMalformed
    }

    // MARK: - Deinitialization

    deinit {
        if !ctxSelfManaged {
            secp256k1_context_destroy(ctx)
        }
    }
}
