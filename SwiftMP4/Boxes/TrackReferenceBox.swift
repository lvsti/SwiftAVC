//
//  TrackReferenceBox.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.06..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct TrackReferenceBox: MP4Box {
    static let fourCC: FourCharCode = "tref"
    var isFullBox: Bool { get { return false } }
    
    func boxParse() -> MP4Parse {
        return MP4Parse.unit(())
    }
}

struct TrackReferenceTypeBox {
    static let trackIDs = Synel(name: "track_IDs", type: (.u32, Synel.anyCount))
    static let isFullBox = false
    
    static func boxParse() -> MP4Parse {
        return parse(TrackReferenceTypeBox.trackIDs)
    }
}

struct HintTrackReferenceBox: MP4Box {
    static let fourCC: FourCharCode = "hint"
    var isFullBox: Bool { get { return TrackReferenceTypeBox.isFullBox } }
    
    func boxParse() -> MP4Parse {
        return TrackReferenceTypeBox.boxParse()
    }
}

struct DescriptionTrackReferenceBox: MP4Box {
    static let fourCC: FourCharCode = "cdsc"
    var isFullBox: Bool { get { return TrackReferenceTypeBox.isFullBox } }
    
    func boxParse() -> MP4Parse {
        return TrackReferenceTypeBox.boxParse()
    }
}

struct HintDependencyTrackReferenceBox: MP4Box {
    static let fourCC: FourCharCode = "hind"
    var isFullBox: Bool { get { return TrackReferenceTypeBox.isFullBox } }
    
    func boxParse() -> MP4Parse {
        return TrackReferenceTypeBox.boxParse()
    }
}

struct VideoDepthTrackReferenceBox: MP4Box {
    static let fourCC: FourCharCode = "vdep"
    var isFullBox: Bool { get { return TrackReferenceTypeBox.isFullBox } }
    
    func boxParse() -> MP4Parse {
        return TrackReferenceTypeBox.boxParse()
    }
}

struct VideoParallaxTrackReferenceBox: MP4Box {
    static let fourCC: FourCharCode = "vplx"
    var isFullBox: Bool { get { return TrackReferenceTypeBox.isFullBox } }
    
    func boxParse() -> MP4Parse {
        return TrackReferenceTypeBox.boxParse()
    }
}
