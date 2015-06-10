//
//  VideoMediaHeaderBox.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.06..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct VideoMediaHeaderBox {
    static let graphicsMode = Synel(name: "graphicsmode", type: (.u16, 1), defaultValue: .UInt16([0]))
    static let opColor = Synel(name: "opcolor", type: (.u16, 3), defaultValue: .UInt16([0, 0, 0]))
}

extension VideoMediaHeaderBox: MP4Box {
    static let fourCC: FourCharCode = "vmhd"
    var isFullBox: Bool { get { return true } }
    
    func boxParse() -> MP4Parse {
        return
            parse(VideoMediaHeaderBox.graphicsMode) >-
            parse(VideoMediaHeaderBox.opColor)
    }
}
