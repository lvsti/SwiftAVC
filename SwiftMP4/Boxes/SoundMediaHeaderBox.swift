//
//  SoundMediaHeaderBox.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.06..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct SoundMediaHeaderBox {
    static let balance = Synel(name: "balance", type: (.u16, 1), defaultValue: .UInt16([0]))
    static let reserved = Synel(name: "reserved", type: (.u16, 1))
}

extension SoundMediaHeaderBox: MP4Box {
    static let fourCC: FourCharCode = "smhd"
    var isFullBox: Bool { get { return true } }
    
    func boxParse() -> MP4Parse {
        return
            parse(SoundMediaHeaderBox.balance) >-
            parse(SoundMediaHeaderBox.reserved)
    }
}

