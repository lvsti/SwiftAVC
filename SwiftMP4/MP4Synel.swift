//
//  MP4Synel.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.31..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

public enum MP4SynelBits: Int {
    case u8 = 8, u16 = 16, u32 = 32, u64 = 64
}


public struct MP4Synel: Equatable, Comparable {
    public let name: String
    public let type: (bits: MP4SynelBits, count: Int?)

    public static let anyCount: Int? = nil
}

extension MP4Synel: Hashable {
    public var hashValue: Int { get { return name.hashValue } }
}

public func ==(lhs: MP4Synel, rhs: MP4Synel) -> Bool {
    return lhs.name == rhs.name
}

public func <(lhs: MP4Synel, rhs: MP4Synel) -> Bool {
    return lhs.name < rhs.name
}

public enum MP4SynelValue {
    case UInt8([Swift.UInt8])
    case UInt16([Swift.UInt16])
    case UInt32([Swift.UInt32])
    case UInt64([Swift.UInt64])
    
    var toU8s: [Swift.UInt8]? { get {
        switch self {
        case .UInt8(let vs): return vs
        default: return nil
        }
    } }

    var toU16s: [Swift.UInt16]? { get {
        switch self {
        case .UInt16(let vs): return vs
        default: return nil
        }
    } }

    var toU32s: [Swift.UInt32]? { get {
        switch self {
        case .UInt32(let vs): return vs
        default: return nil
        }
    } }

    var toU64s: [Swift.UInt64]? { get {
        switch self {
        case .UInt64(let vs): return vs
        default: return nil
        }
    } }
}
