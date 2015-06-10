//
//  MediaHeaderBox.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.06..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct MediaHeaderBox {
    static let creationTime64 = Synel(name: "creation_time", type: (.u64, 1))
    static let modificationTime64 = Synel(name: "modification_time", type: (.u64, 1))
    static let duration64 = Synel(name: "duration", type: (.u64, 1))
    
    static let creationTime = Synel(name: "creation_time", type: (.u32, 1))
    static let modificationTime = Synel(name: "modification_time", type: (.u32, 1))
    static let duration = Synel(name: "duration", type: (.u32, 1))
    
    static let timescale = Synel(name: "timescale", type: (.u32, 1))
    static let language = Synel(name: "language", type: (.u16, 1))
    static let predefined = Synel(name: "pre_defined", type: (.u16, 1))
}

extension MediaHeaderBox: MP4Box {
    static let fourCC: FourCharCode = "mdhd"
    var isFullBox: Bool { get { return true } }
    
    func boxParse() -> MP4Parse {
        return
            parseIf({ mps in mps.dictionary[FullBox.version]![0].toU8s![0] == 1 }) {
                parse(MediaHeaderBox.creationTime64) >-
                parse(MediaHeaderBox.modificationTime64) >-
                parse(MediaHeaderBox.timescale) >-
                parse(MediaHeaderBox.duration64)
            } >-
            parseIf({ mps in mps.dictionary[FullBox.version]![0].toU8s![0] == 0 }) {
                parse(MediaHeaderBox.creationTime) >-
                parse(MediaHeaderBox.modificationTime) >-
                parse(MediaHeaderBox.timescale) >-
                parse(MediaHeaderBox.duration)
            } >-
            parse(MediaHeaderBox.language) >-
            parse(MediaHeaderBox.predefined)
    }
}

