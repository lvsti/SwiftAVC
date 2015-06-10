//
//  TrackHeader.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.06..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct TrackHeaderBox {
    static let creationTime64 = Synel(name: "creation_time", type: (.u64, 1))
    static let modificationTime64 = Synel(name: "modification_time", type: (.u64, 1))
    static let duration64 = Synel(name: "duration", type: (.u64, 1))
    
    static let creationTime = Synel(name: "creation_time", type: (.u32, 1))
    static let modificationTime = Synel(name: "modification_time", type: (.u32, 1))
    static let duration = Synel(name: "duration", type: (.u32, 1))

    static let trackID = Synel(name: "track_ID", type: (.u32, 1))

    static let reserved1 = Synel(name: "reserved1", type: (.u32, 1))
    static let reserved2 = Synel(name: "reserved2", type: (.u32, 2))
    static let reserved3 = Synel(name: "reserved3", type: (.u16, 1))

    static let layer = Synel(name: "layer", type: (.u16, 1), defaultValue: .UInt16([0]))
    static let alternateGroup = Synel(name: "alternate_group", type: (.u16, 1), defaultValue: .UInt16([0]))
    static let volume = Synel(name: "volume", type: (.u16, 1), defaultValue: .UInt16([0x0100]))
    
    static let matrix = Synel(name: "matrix", type: (.u32, 9), defaultValue: .UInt32([0x00010000, 0, 0, 0, 0x00010000, 0, 0, 0, 0x40000000]))
    static let width = Synel(name: "width", type: (.u32, 1))
    static let height = Synel(name: "height", type: (.u32, 1))
}

extension TrackHeaderBox: MP4Box {
    static let fourCC: FourCharCode = "tkhd"
    var isFullBox: Bool { get { return true } }
    
    func boxParse() -> MP4Parse {
        return
            parseIf({ mps in mps.dictionary[FullBox.version]![0].toU8s![0] == 1 }) {
                parse(TrackHeaderBox.creationTime64) >-
                parse(TrackHeaderBox.modificationTime64) >-
                parse(TrackHeaderBox.trackID) >-
                parse(TrackHeaderBox.reserved1) >-
                parse(TrackHeaderBox.duration64)
            } >-
            parseIf({ mps in mps.dictionary[FullBox.version]![0].toU8s![0] == 0 }) {
                parse(TrackHeaderBox.creationTime) >-
                parse(TrackHeaderBox.modificationTime) >-
                parse(TrackHeaderBox.trackID) >-
                parse(TrackHeaderBox.reserved1) >-
                parse(TrackHeaderBox.duration)
            } >-
            parse(TrackHeaderBox.reserved2) >-
            parse(TrackHeaderBox.layer) >-
            parse(TrackHeaderBox.alternateGroup) >-
            parse(TrackHeaderBox.volume) >-
            parse(TrackHeaderBox.reserved3) >-
            parse(TrackHeaderBox.matrix) >-
            parse(TrackHeaderBox.width) >-
            parse(TrackHeaderBox.height)
    }
}
