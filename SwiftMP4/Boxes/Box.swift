//
//  Box.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.06..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct Box {
    static let size = Synel(name: "size", type: (.u32, 1))
    static let type = Synel(name: "type", type: (.u32, 1))
    static let largeSize = Synel(name: "largesize", type: (.u64, 1))
    static let userType = Synel(name: "usertype", type: (.u8, 16))

    static func boxParse() -> MP4Parse {
        return
            parse(Box.size) >-
            parse(Box.type) >-
            parseIf({ mps in mps.dictionary[Box.size]!.toU32s![0] == 1 }) {
                parse(Box.largeSize)
            } >-
            parseIf({ mps in mps.dictionary[Box.type]!.toU32s![0] == "uuid" }) {
                parse(Box.userType)
            }
    }

}