//
//  MovieBox.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.06..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct MovieBox: MP4Box {
    static let fourCC: FourCharCode = "moov"
    var isFullBox: Bool { get { return false } }
    
    func boxParse() -> MP4Parse {
        return MP4Parse.unit(())
    }
}
