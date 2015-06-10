//
//  MovieHeaderBox.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.06..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct MovieHeaderBox {
    static let creationTime64 = Synel(name: "creation_time", type: (.u64, 1))
    static let modificationTime64 = Synel(name: "modification_time", type: (.u64, 1))
    static let duration64 = Synel(name: "duration", type: (.u64, 1))
    
    static let creationTime = Synel(name: "creation_time", type: (.u32, 1))
    static let modificationTime = Synel(name: "modification_time", type: (.u32, 1))
    static let duration = Synel(name: "duration", type: (.u32, 1))
    
    static let timescale = Synel(name: "timescale", type: (.u32, 1))
    
    static let rate = Synel(name: "rate", type: (.u32, 1), defaultValue: .UInt32([0x00010000]))
    static let volume = Synel(name: "volume", type: (.u16, 1), defaultValue: .UInt16([0x0100]))
    static let reserved1 = Synel(name: "reserved1", type: (.u16, 1))
    static let reserved2 = Synel(name: "reserved2", type: (.u32, 2))
    static let matrix = Synel(name: "matrix", type: (.u32, 9), defaultValue: .UInt32([0x00010000, 0, 0, 0, 0x00010000, 0, 0, 0, 0x40000000]))
    static let predefined = Synel(name: "predefined", type: (.u32, 6))
    static let nextTrackID = Synel(name: "next_track_ID", type: (.u32, 1))
}

extension MovieHeaderBox: MP4Box {
    static let fourCC: FourCharCode = "mvhd"
    var isFullBox: Bool { get { return true } }
    
    func boxParse() -> MP4Parse {
        return
            parseIf({ mps in mps.dictionary[FullBox.version]![0].toU8s![0] == 1 }) {
                parse(MovieHeaderBox.creationTime64) >-
                parse(MovieHeaderBox.modificationTime64) >-
                parse(MovieHeaderBox.timescale) >-
                parse(MovieHeaderBox.duration64)
            } >-
            parseIf({ mps in mps.dictionary[FullBox.version]![0].toU8s![0] == 0 }) {
                parse(MovieHeaderBox.creationTime) >-
                parse(MovieHeaderBox.modificationTime) >-
                parse(MovieHeaderBox.timescale) >-
                parse(MovieHeaderBox.duration)
            } >-
            parse(MovieHeaderBox.rate) >-
            parse(MovieHeaderBox.volume) >-
            parse(MovieHeaderBox.reserved1) >-
            parse(MovieHeaderBox.reserved2) >-
            parse(MovieHeaderBox.matrix) >-
            parse(MovieHeaderBox.predefined) >-
            parse(MovieHeaderBox.nextTrackID)
    }
}
