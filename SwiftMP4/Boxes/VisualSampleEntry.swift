//
//  VisualSampleEntry.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.11..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation


struct VisualSampleEntry {
    static let predefined1 = Synel(name: "predefined1", type: (.u16, 1))
    static let reserved1 = Synel(name: "reserved1", type: (.u16, 1))
    static let predefined2 = Synel(name: "predefined2", type: (.u32, 3))
    static let width = Synel(name: "width", type: (.u16, 1))
    static let height = Synel(name: "height", type: (.u16, 1))
    static let horizontalResolution = Synel(name: "horizresolution", type: (.u32, 1), defaultValue: .UInt32([0x00480000]))
    static let verticalResolution = Synel(name: "vertresolution", type: (.u32, 1), defaultValue: .UInt32([0x00480000]))
    static let reserved2 = Synel(name: "reserved2", type: (.u32, 1))
    static let frameCount = Synel(name: "frame_count", type: (.u16, 1), defaultValue: .UInt16([1]))
    static let compressorName = Synel(name: "compressorname", type: (.u8, 32))
    static let depth = Synel(name: "depth", type: (.u16, 1), defaultValue: .UInt16([0x0018]))
    static let predefined3 = Synel(name: "predefined3", type: (.u16, 1))

    static func boxParse() -> MP4Parse {
        return
            SampleEntry.boxParse() >-
            parse(VisualSampleEntry.predefined1) >-
            parse(VisualSampleEntry.reserved1) >-
            parse(VisualSampleEntry.predefined2) >-
            parse(VisualSampleEntry.width) >-
            parse(VisualSampleEntry.height) >-
            parse(VisualSampleEntry.horizontalResolution) >-
            parse(VisualSampleEntry.verticalResolution) >-
            parse(VisualSampleEntry.reserved2) >-
            parse(VisualSampleEntry.frameCount) >-
            parse(VisualSampleEntry.compressorName) >-
            parse(VisualSampleEntry.depth) >-
            parse(VisualSampleEntry.predefined3)
    }
}
