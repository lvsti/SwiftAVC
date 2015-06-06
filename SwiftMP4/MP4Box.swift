//
//  MP4Box.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.31..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

extension FourCharCode {
    public static func fromString(str: String) -> FourCharCode {
        let chars = str.fileSystemRepresentation()
        assert(chars.count == 5)
        
        var result: FourCharCode = 0
        for i in 0...3 {
            result <<= 8
            result |= FourCharCode(chars[i])
        }
        return result
    }
    
    public func toString() -> String {
        var result = ""
        for i in 0...3 {
            let ch = (self >> (24 - i*8)) & 0xff
            result += String(Character(UnicodeScalar(ch)))
        }
        return result
    }
}

extension FourCharCode: StringLiteralConvertible {
    public typealias ExtendedGraphemeClusterLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(FourCharCode.fromString(value))
    }
    
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.init(FourCharCode.fromString(value))
    }
    
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.init(FourCharCode.fromString(value))
    }
}

extension FourCharCode: Printable {
    public var description: String { get { return self.toString() } }
}


protocol MP4Box {
    class var fourCC: FourCharCode { get }
    var isFullBox: Bool { get }
    func boxParse() -> MP4Parse
}

public struct BoxDescriptor {
    public let properties: [Synel:SynelValue]
    public let frameRange: NSRange
    public let payloadRange: NSRange
    public let children: [BoxDescriptor]
    
    public var type: FourCharCode { get {
        return properties[Box.type]!.toU32s![0]
    } }
    public var size: Int { get {
        return frameRange.length
    } }
}



