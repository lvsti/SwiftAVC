//
//  MP4Parse.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.31..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

typealias SynelDictionary = [Synel:SynelValue]

struct MP4ParseState {
    let data: NSData
    let offset: Int
    let endOffset: Int
    let boxes: [BoxDescriptor]
    let dictionary: SynelDictionary
    
    init(data: NSData, offset: Int = 0, endOffset: Int? = nil, boxes: [BoxDescriptor] = [], dictionary: SynelDictionary = SynelDictionary()) {
        self.data = data
        self.offset = offset
        self.endOffset = endOffset != nil ? endOffset! : self.data.length
        self.boxes = boxes
        self.dictionary = dictionary
    }
    
    func advancedBy(delta: Int) -> MP4ParseState {
        return MP4ParseState(data: self.data,
                             offset: self.offset + delta,
                             endOffset: self.endOffset,
                             boxes: self.boxes,
                             dictionary: self.dictionary)
    }
    
    func committingBox(box: BoxDescriptor) -> MP4ParseState {
        var newBoxes = self.boxes
        newBoxes.append(box)
        return MP4ParseState(data: self.data,
                             offset: NSMaxRange(box.frameRange),
                             endOffset: self.endOffset,
                             boxes: newBoxes,
                             dictionary: [:])
    }
    
    func settingValue(value: SynelValue, forKey key: Synel) -> MP4ParseState {
        var newDictionary = self.dictionary
        newDictionary.updateValue(value, forKey: key)
        return MP4ParseState(data: self.data,
                             offset: self.offset,
                             endOffset: self.endOffset,
                             boxes: self.boxes,
                             dictionary: newDictionary)
    }
    
    func withEndOffset(endOffset: Int) -> MP4ParseState {
        return MP4ParseState(data: self.data,
                             offset: self.offset,
                             endOffset: endOffset,
                             boxes: self.boxes,
                             dictionary: self.dictionary)
    }
}



public typealias MP4ParseError = String

typealias MP4FourCCParse = EitherState<MP4ParseError, MP4ParseState, String>
typealias MP4Parse = EitherState<MP4ParseError, MP4ParseState, ()>

extension EitherState {
    var runMP4Parse: S -> (Either<E,A>, S) { return self.runEitherState }
}

func mp4Lambda(f: MP4ParseState -> MP4Parse) -> (MP4ParseState -> MP4Parse) {
    return f
}

protocol ByteOrderInitializable {
    init(bigEndian: Self)
}

extension UInt8 : ByteOrderInitializable {
    init(bigEndian: UInt8) {
        self.init(bigEndian)
    }
}

extension UInt16 : ByteOrderInitializable {}
extension UInt32 : ByteOrderInitializable {}
extension UInt64 : ByteOrderInitializable {}


func parseItems<T : ByteOrderInitializable>(ptr: UnsafePointer<UInt8>, count: Int) -> [T] {
    var items: [T] = []
    var tptr = UnsafePointer<T>(ptr)
    for i in 0..<count {
        items.append(T(bigEndian: tptr[i]))
    }
    return items
}

func parse(synel: Synel) -> MP4Parse {
    return
        MP4Parse.get() >>-
        mp4Lambda { mps in
            let itemSize = synel.type.0.rawValue / 8
            var itemCount = 0
            
            if let synelCount = synel.type.1 {
                itemCount = synelCount
            } else {
                let remainingByteCount = mps.endOffset - mps.offset
                if remainingByteCount % itemSize != 0 {
                    return MP4Parse.fail("invalid box size detected while parsing \(synel.name)")
                }
                itemCount = remainingByteCount / itemSize
            }
            
            if mps.offset + itemSize * itemCount > mps.endOffset {
                return MP4Parse.fail("unexpected EOS while parsing \(synel.name)")
            }
            
            let ptr = UnsafePointer<UInt8>(mps.data.bytes).advancedBy(mps.offset)
            var value: SynelValue
            
            switch synel.type.0 {
            case .u8: value = SynelValue.UInt8(parseItems(ptr, itemCount)); break
            case .u16: value = SynelValue.UInt16(parseItems(ptr, itemCount)); break
            case .u32: value = SynelValue.UInt32(parseItems(ptr, itemCount)); break
            case .u64: value = SynelValue.UInt64(parseItems(ptr, itemCount)); break
            }
            
            let newMPS = mps.settingValue(value, forKey: synel).advancedBy(itemSize * itemCount)
    
            return MP4Parse.put(newMPS)
        }
}
