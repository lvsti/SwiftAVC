//
//  MP4.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.30..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct MP4BoxSynel {
    static let size = MP4Synel(name: "size", type: (.u32, 1))
    static let type = MP4Synel(name: "type", type: (.u32, 1))
    static let largeSize = MP4Synel(name: "largesize", type: (.u64, 1))
    static let userType = MP4Synel(name: "usertype", type: (.u8, 16))
}

struct MP4FullBoxSynel {
    static let version = MP4Synel(name: "version", type: (.u8, 1))
    static let flags = MP4Synel(name: "flags", type: (.u8, 3))
}

struct MP4FileTypeBoxSynel {
    static let majorBrand = MP4Synel(name: "major_brand", type: (.u32, 1))
    static let minorVersion = MP4Synel(name: "minor_version", type: (.u32, 1))
    static let compatibleBrands = MP4Synel(name: "compatible_brands", type: (.u32, MP4Synel.anyCount))
}


struct MP4TempSynel {
    static let boxStartOffset = Synel(name: "tmp_boxStartOffset", type: (.u32, 1))
    static let stashedEndOffset = Synel(name: "tmp_stashedEndOffset", type: (.u32, 1))
}

func parseFullBoxHeader() -> MP4Parse {
    return
        parse(MP4FullBoxSynel.version) >-
        parse(MP4FullBoxSynel.flags)
}

let mp4BoxParses: [FourCharCode : () -> MP4Parse] = [
    MP4BoxType.fileType.fourCC: {
        parse(MP4FileTypeBoxSynel.majorBrand) >-
        parse(MP4FileTypeBoxSynel.minorVersion) >-
        parse(MP4FileTypeBoxSynel.compatibleBrands)
    },
    
]



func parseBox() -> MP4Parse {
    return
        MP4Parse.get() >>-
        mp4Lambda { mps in
            let newMPS = mps.settingValue(SynelValue.UInt32([UInt32(mps.offset)]), forKey: MP4TempSynel.boxStartOffset)
            return MP4Parse.put(newMPS)
        } >-
        parse(MP4BoxSynel.size) >-
        parse(MP4BoxSynel.type) >-
        parseIf({ mps in mps.dictionary[MP4BoxSynel.size]!.toU32s![0] == 1 }) {
            parse(MP4BoxSynel.largeSize)
        } >-
        parseIf({ mps in mps.dictionary[MP4BoxSynel.type]!.toU32s![0] == MP4BoxType.uuid.fourCC }) {
            parse(MP4BoxSynel.userType)
        } >-
        MP4Parse.get() >>-
        mp4Lambda { mps in
            let size = mps.dictionary[MP4BoxSynel.size]!.toU32s![0]
            let lastBoxStartOffset = Int(mps.dictionary[MP4TempSynel.boxStartOffset]!.toU32s![0])

            let hasLargeSize = (size == 1)
            let extendsToEOF = (size == 0)
            
            var frameRange = NSMakeRange(lastBoxStartOffset, 0)
            
            if hasLargeSize {
                let largeSize = mps.dictionary[MP4BoxSynel.largeSize]!.toU64s![0]
                frameRange.length = Int(largeSize)
            } else if extendsToEOF {
                frameRange.length = mps.data.length - frameRange.location
            } else {
                frameRange.length = Int(size)
            }

            let newMPS = mps
                .withEndOffset(NSMaxRange(frameRange))
                .settingValue(SynelValue.UInt32([UInt32(mps.endOffset)]), forKey: MP4TempSynel.stashedEndOffset)
            return MP4Parse.put(newMPS)
        } >-
        MP4Parse.get() >>-
        mp4Lambda { mps in
            let type = mps.dictionary[MP4BoxSynel.type]!.toU32s![0]
            if let boxParse = mp4BoxParses[type] {
                return boxParse()
            }
            return MP4Parse.unit(())
        } >-
        MP4Parse.get() >>-
        mp4Lambda { mps in
            let type = mps.dictionary[MP4BoxSynel.type]!.toU32s![0]
            let lastBoxStartOffset = Int(mps.dictionary[MP4TempSynel.boxStartOffset]!.toU32s![0])
            let frameRange = NSMakeRange(lastBoxStartOffset, mps.endOffset - lastBoxStartOffset)
            let payloadRange = NSMakeRange(mps.offset, mps.endOffset - mps.offset)
            var children: [BoxDescriptor] = []
            
            let isKnownBoxType = mp4BoxParses[type] != nil

            if payloadRange.length > 0 && isKnownBoxType {
                // nonempty and known box, parse contents
                let payloadMPS = MP4ParseState(data: mps.data,
                                               offset: payloadRange.location,
                                               endOffset: NSMaxRange(payloadRange))
                let (ppResult, ppState) = parseBoxes().runMP4Parse(payloadMPS)
                switch (ppResult) {
                case .Left(let errorBox):
                    let type = mps.dictionary[MP4BoxSynel.type]!.toU32s![0]
                    return MP4Parse.fail("failed to parse payload of '\(FourCharCode.toString(type))': \(errorBox.unbox())")
                case .Right(_): children = ppState.boxes
                }
            }
            
            let box = BoxDescriptor(properties: mps.dictionary,
                                    frameRange: frameRange,
                                    payloadRange: payloadRange,
                                    children: children)

            let stashedEndOffset = Int(mps.dictionary[MP4TempSynel.stashedEndOffset]!.toU32s![0])
            let newMPS = mps.committingBox(box).withEndOffset(stashedEndOffset)
            
            return MP4Parse.put(newMPS)
        }
}

func parseIf(predicate: MP4ParseState -> Bool, parse: () -> MP4Parse) -> MP4Parse {
    return
        MP4Parse.get() >>-
        mp4Lambda { mps in
            predicate(mps) ? parse() : MP4Parse.unit(())
        }
}

func parseWhile(predicate: MP4ParseState -> Bool, parse: () -> MP4Parse) -> MP4Parse {
    return
        MP4Parse.get() >>-
        mp4Lambda { mps in
            if !predicate(mps) {
                return MP4Parse.unit(())
            }
            return parse() >- parseWhile(predicate, parse)
        }
}

func parseBoxes() -> MP4Parse {
    return
        parseWhile({ mps in mps.offset < mps.endOffset }) {
            parseBox()
        }
}


public func parseMP4Data(data: NSData) -> Either<MP4ParseError, [BoxDescriptor]> {
    let mps = MP4ParseState(data: data)
    let (result, state) = parseBoxes().runMP4Parse(mps)
    switch result {
    case .Left(let errorBox): return .Left(errorBox)
    case .Right(_): return .Right(Box(state.boxes))
    }
}
