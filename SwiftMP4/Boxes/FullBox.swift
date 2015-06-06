//
//  FullBox.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.06..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct FullBox {
    static let version = Synel(name: "version", type: (.u8, 1))
    static let flags = Synel(name: "flags", type: (.u8, 3))
    
    static func boxParse() -> MP4Parse {
        return
            parse(FullBox.version) >-
            parse(FullBox.flags)
    }
}

