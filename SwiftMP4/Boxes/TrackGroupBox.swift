//
//  TrackGroupBox.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.06..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct TrackGroupBox: MP4Box {
    static let fourCC: FourCharCode = "trgr"
    var isFullBox: Bool { get { return false } }
    
    func boxParse() -> MP4Parse {
        return MP4Parse.unit(())
    }
}

struct TrackGroupTypeBox {
    static let trackGroupID = Synel(name: "track_group_id", type: (.u32, 1))
    static let isFullBox = true
    
    static func boxParse() -> MP4Parse {
        return parse(TrackGroupTypeBox.trackGroupID)
    }
}

struct MultiSourceTrackGroupTypeBox: MP4Box {
    static let fourCC: FourCharCode = "msrc"
    var isFullBox: Bool { get { return TrackGroupTypeBox.isFullBox } }
    
    func boxParse() -> MP4Parse {
        return TrackGroupTypeBox.boxParse()
    }
}

