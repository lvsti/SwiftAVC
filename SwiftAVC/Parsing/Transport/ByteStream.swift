//
//  ByteStream.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.14..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation


struct ByteStreamParseState {
    let data: NSData
    let offset: Int
    let lastNALDataRange: NSRange?
    
    init(data: NSData, offset: Int, nalDataRange: NSRange?) {
        self.data = data
        self.offset = offset
        self.lastNALDataRange = nalDataRange
    }
    
    func advancedBy(delta: Int) -> ByteStreamParseState {
        return ByteStreamParseState(data: data, offset: offset + delta, nalDataRange: lastNALDataRange)
    }
    
    func settingNALRange(range: NSRange) -> ByteStreamParseState {
        return ByteStreamParseState(data: data, offset: offset, nalDataRange: range)
    }
}

extension EitherState {
    var runByteStreamParse: S -> (Either<E,A>, S) { return self.runEitherState }
}

typealias ByteStreamParseError = String
typealias ByteStreamParse = EitherState<ByteStreamParseError, ByteStreamParseState, ()>

private func bsLambda(f: ByteStreamParseState -> ByteStreamParse) -> (ByteStreamParseState -> ByteStreamParse) {
    return f
}

private func parseStartCodePrefixOne3bytes() -> ByteStreamParse {
    return ByteStreamParse.get() >>-
        bsLambda { bsps in
            if bsps.offset + 3 > bsps.data.length {
                return ByteStreamParse.fail("parseStartCodePrefixOne3bytes: unexpected EOS")
            }
            
            let ptr = UnsafePointer<UInt8>(bsps.data.bytes).advancedBy(bsps.offset)
            if ptr[0] == 0 && ptr[1] == 0 && ptr[2] == 1 {
                return ByteStreamParse.put(bsps.advancedBy(3))
            }
            
            return ByteStreamParse.fail("synStartCodePrefixOne3bytes: unexpected data")
        }
}

private func parseLeadingZeroes() -> ByteStreamParse {
    return ByteStreamParse.get() >>-
        bsLambda { bsps in
            if bsps.offset + 3 > bsps.data.length {
                return ByteStreamParse.fail("parseLeadingZeroes: unexpected EOS")
            }
            
            var delta = 0
            var ptr = UnsafePointer<UInt8>(bsps.data.bytes).advancedBy(bsps.offset)
            while ptr[0] == 0 && !(ptr[1] == 0 && ptr[2] == 1) {
                ptr = ptr.advancedBy(1)
                ++delta
            }
            
            return ByteStreamParse.put(bsps.advancedBy(delta))
        }
}

private func findNALTerminationSequenceOffset(bsps: ByteStreamParseState) -> Int? {
    var delta = 0
    var ptr = UnsafePointer<UInt8>(bsps.data.bytes).advancedBy(bsps.offset)
    while bsps.offset + delta <= bsps.data.length &&
          !(ptr[0] == 0 && ptr[1] == 0 && (ptr[2] == 0 || ptr[2] == 1)) {
        ptr = ptr.advancedBy(1)
        ++delta
    }
    
    return bsps.offset + delta <= bsps.data.length ? delta : nil
}

private func parseTrailingZeroes() -> ByteStreamParse {
    return ByteStreamParse.get() >>-
        bsLambda { bsps in
            var delta = 0
            var ptr = UnsafePointer<UInt8>(bsps.data.bytes).advancedBy(bsps.offset)
            while bsps.offset + delta < bsps.data.length {
                if (ptr[0] != 0) {
                    return ByteStreamParse.put(bsps.advancedBy(delta)) >-
                           ByteStreamParse.fail("parseTrailingZeroes: unexpected data")
                }
                
                if bsps.offset + delta + 3 <= bsps.data.length && (ptr[1] == 0 && ptr[2] == 1) ||
                   bsps.offset + delta + 4 <= bsps.data.length && (ptr[1] == 0 && ptr[2] == 0 && ptr[3] == 1) {
                    // delimiter found
                    break
                }
                ptr = ptr.advancedBy(1)
                ++delta
            }
            
            return ByteStreamParse.put(bsps.advancedBy(delta))
        }
}

private func parseNextNALUnitBytes() -> ByteStreamParse {
    return
        parseLeadingZeroes() >-
        parseStartCodePrefixOne3bytes() >-
        ByteStreamParse.get() >>-
        bsLambda { bsps in
            if let nalUnitLength = findNALTerminationSequenceOffset(bsps) {
                let newBsps = bsps.settingNALRange(NSMakeRange(bsps.offset, nalUnitLength)).advancedBy(nalUnitLength)
                return ByteStreamParse.put(newBsps)
            }
            return ByteStreamParse.fail("parseNextNALUnitBytes: missing NAL termination sequence")
        } >-
        parseTrailingZeroes()
}

public func getNALUnitRangesFromByteStream(data: NSData) -> [NSRange] {
    var bsps = ByteStreamParseState(data: data, offset: 0, nalDataRange: nil)
    var nalUnitRanges: [NSRange] = []
    
    while (true) {
        let (result, newBsps) = parseNextNALUnitBytes().runByteStreamParse(bsps)
        
        switch result {
        case .Left(let box):
            println("ERROR: \(box.unwrap())")
            return nalUnitRanges
        case .Right(let box):
            if let range = newBsps.lastNALDataRange {
                nalUnitRanges.append(range)
            }
            bsps = newBsps
        }
        
        if bsps.offset >= bsps.data.length {
            break
        }
    }
    
    return nalUnitRanges
}

// spec 7.3.1
public func unescapeByteStreamNALUnitBytes(escapedBytes: NSData) -> NSData {
    let kEmulationPreventionSequence: [Byte] = [0, 0, 3];
    let epsData = NSData(bytes: UnsafePointer<Byte>(kEmulationPreventionSequence),
        length: kEmulationPreventionSequence.count)
    
    var epsRange = escapedBytes.rangeOfData(epsData,
        options: NSDataSearchOptions(),
        range: NSMakeRange(0, escapedBytes.length))
    if epsRange.location == NSNotFound {
        return escapedBytes
    }
    
    var offset = 0
    let unescapedBytes = NSMutableData(capacity: escapedBytes.length)!
    
    while epsRange.location != NSNotFound {
        unescapedBytes.appendBytes(UnsafePointer<Byte>(escapedBytes.bytes).advancedBy(offset),
            length: epsRange.location + 2)
        offset += epsRange.location + 3
        epsRange = escapedBytes.rangeOfData(epsData,
            options: NSDataSearchOptions(),
            range: NSMakeRange(offset, escapedBytes.length - offset))
    }
    
    unescapedBytes.appendBytes(UnsafePointer<Byte>(escapedBytes.bytes).advancedBy(offset),
        length: escapedBytes.length - offset)
    
    return unescapedBytes
}


