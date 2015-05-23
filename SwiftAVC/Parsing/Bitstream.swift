//
//  Bitstream.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.06..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation


let kLeadBitmask: [UInt8] = [0b11111111, 0b01111111, 0b00111111, 0b00011111, 0b00001111, 0b00000111, 0b00000011, 0b00000001]


struct Bitstream {
    let data: NSData
    let length: Int

    init(data: NSData) {
        self.data = data
        self.length = data.length * 8
    }
    
    func read(offset: Int, count: Int) -> Int? {
        assert(count <= sizeof(Int)*8)
        
        let startIdx = offset / 8
        let endIdx = (offset + count) / 8
        
        if endIdx >= data.length {
            return nil
        }
        
        let ptr = UnsafePointer<UInt8>(data.bytes)
        var value: Int = Int(ptr[startIdx] & kLeadBitmask[offset % 8])
        
        if endIdx > startIdx + 1 {
            for i in startIdx+1..<endIdx {
                value <<= 8
                value |= Int(ptr[i])
            }
        }
        
        let newBitOffset = (offset + count) % 8
        if newBitOffset > 0 {
            if startIdx == endIdx {
                value >>= 8 - newBitOffset
            } else {
                value <<= Int(newBitOffset)
                value |= Int(ptr[endIdx] >> (8 - newBitOffset))
            }
        }
        
        return value
    }
}

