//
//  EditListBox.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.06..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct EditListBox {
    static let entryCount = Synel(name: "entry_count", type: (.u32, 1))
    static let segmentDuration64 = Synel(name: "segment_duration", type: (.u64, 1))
    static let mediaTime64 = Synel(name: "media_time", type: (.u64, 1))
    static let segmentDuration = Synel(name: "segment_duration", type: (.u32, 1))
    static let mediaTime = Synel(name: "media_time", type: (.u32, 1))
    static let mediaRateInteger = Synel(name: "media_rate_integer", type: (.u16, 1))
    static let mediaRateFraction = Synel(name: "media_rate_fraction", type: (.u16, 1))
}

extension EditListBox: MP4Box {
    static let fourCC: FourCharCode = "elst"
    var isFullBox: Bool { get { return true } }
    
    func boxParse() -> MP4Parse {
        return
            parse(EditListBox.entryCount) >-
            MP4Parse.get() >>-
            mp4Lambda { mps in
                let entryCount:Int = Int(mps.dictionary[EditListBox.entryCount]![0].toU32s![0])
                let values = [Int](0..<entryCount)
                
                return
                    parseForEach(values) { _ in
                        parseIf({ mps in mps.dictionary[FullBox.version]![0].toU8s![0] == 1 }) {
                            parse(EditListBox.segmentDuration64) >-
                            parse(EditListBox.mediaTime64)
                        } >-
                        parseIf({ mps in mps.dictionary[FullBox.version]![0].toU8s![0] == 0 }) {
                            parse(EditListBox.segmentDuration) >-
                            parse(EditListBox.mediaTime)
                        } >-
                        parse(EditListBox.mediaRateInteger) >-
                        parse(EditListBox.mediaRateFraction)
                    }
            }
    }
}

