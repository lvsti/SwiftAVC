//
//  HandlerReferenceBox.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.06..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct HandlerReferenceBox {
    static let predefined = Synel(name: "pre_defined", type: (.u32, 1))
    static let handlerType = Synel(name: "handler_type", type: (.u32, 1))
    static let reserved = Synel(name: "reserved", type: (.u32, 3))
    static let name = Synel(name: "name", type: (.u8, Synel.nullTerminated))
    
    enum HandlerType: FourCharCode {
        case Video = "vide"
        case Sound = "soun"
        case Hint = "hint"
        case Meta = "meta"
        case AuxiliaryVideo = "auxv"
    }
}

extension HandlerReferenceBox: MP4Box {
    static let fourCC: FourCharCode = "hdlr"
    var isFullBox: Bool { get { return true } }
    
    func boxParse() -> MP4Parse {
        return
            parse(HandlerReferenceBox.predefined) >-
            parse(HandlerReferenceBox.handlerType) >-
            parse(HandlerReferenceBox.reserved) >-
            parse(HandlerReferenceBox.name)
    }

}

