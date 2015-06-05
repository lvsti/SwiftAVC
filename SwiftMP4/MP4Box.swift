//
//  MP4Box.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.31..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

extension FourCharCode {
    static func fromString(str: String) -> FourCharCode {
        let chars = str.fileSystemRepresentation()
        assert(chars.count == 5)
        
        var result: FourCharCode = 0
        for i in 0...3 {
            result <<= 8
            result |= FourCharCode(chars[i])
        }
        return result
    }
    
    func toString() -> String {
        var result = ""
        for i in 0...3 {
            let ch = (self >> (24 - i*8)) & 0xff
            result += String(Character(UnicodeScalar(ch)))
        }
        return result
    }
}


public struct MP4BoxType {
    let fourCC: FourCharCode
    
    static let fileType = MP4BoxType(fourCCString: "ftyp")
    static let uuid = MP4BoxType(fourCCString: "uuid")
    static let movie = MP4BoxType(fourCCString: "moov")
    static let movieHeader = MP4BoxType(fourCCString: "mvhd")
    static let track = MP4BoxType(fourCCString: "trak")
    static let trackHeader = MP4BoxType(fourCCString: "tkhd")
    static let trackReference = MP4BoxType(fourCCString: "tref")
    static let mediaData = MP4BoxType(fourCCString: "mdat")
    
    init(fourCC: FourCharCode) {
        self.fourCC = fourCC
    }
    
    init(fourCCString: String) {
        self.fourCC = FourCharCode.fromString(fourCCString)
    }
}

extension MP4BoxType : Equatable, Hashable {
    public var hashValue: Int { get { return Int(self.fourCC) } }
}

public func ==(lhs: MP4BoxType, rhs: MP4BoxType) -> Bool {
    return lhs.fourCC == rhs.fourCC
}

extension MP4BoxType : Printable {
    public var description: String { get {
        return self.fourCC.toString()
    } }
}


public struct MP4Box {
    public let properties: [MP4Synel:MP4SynelValue]
    public let frameRange: NSRange
    public let payloadRange: NSRange
    public let children: [MP4Box]
    
    public var type: MP4BoxType { get {
        return MP4BoxType(fourCC: properties[MP4BoxSynel.type]!.toU32s![0])
    } }
    public var size: Int { get {
        return frameRange.length
    } }
}



