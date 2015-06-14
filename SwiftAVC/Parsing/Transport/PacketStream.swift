//
//  PacketStream.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.14..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

public func getNALUnitRangesFromPacketStream(data: NSData, lengthSize: Int = 4) -> [NSRange] {
    assert(lengthSize == 1 || lengthSize == 2 || lengthSize == 4, "unsupported length field size (\(lengthSize))")
    var ranges = [NSRange]()
    var offset = 0
    var ptr = UnsafePointer<UInt8>(data.bytes)
    
    while offset + lengthSize <= data.length {
        let packetLength: () -> Int = {
            switch lengthSize {
            case 1: return Int(ptr.memory)
            case 2: return Int(UInt16(bigEndian: UnsafePointer<UInt16>(ptr).memory))
            case 4: return Int(UInt32(bigEndian: UnsafePointer<UInt32>(ptr).memory))
            default: return 0
            }
        }
        
        let range = NSMakeRange(offset + lengthSize, packetLength())
        ranges.append(range)
        
        offset = NSMaxRange(range)
        ptr = ptr.advancedBy(lengthSize + range.length)
    }
    
    return ranges
}
