//
//  MediaDataBox.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.06..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct MediaDataBox {
    static let data = Synel(name: "data", type: (.u8, Synel.anyCount))
}

extension MediaDataBox: MP4Box {
    static let fourCC: FourCharCode = "mdat"
    var isFullBox: Bool { get { return false } }
    
    func boxParse() -> MP4Parse {
        return
            MP4Parse.get() >>-
            mp4Lambda { mps in
                // let's not parse the payload byte by byte
                MP4Parse.put(mps.advancedBy(mps.endOffset - mps.offset))
            }
    }
}
