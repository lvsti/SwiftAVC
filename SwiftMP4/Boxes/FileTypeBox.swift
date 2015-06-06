//
//  FileType.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.06..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct FileTypeBox {
    static let majorBrand = Synel(name: "major_brand", type: (.u32, 1))
    static let minorVersion = Synel(name: "minor_version", type: (.u32, 1))
    static let compatibleBrands = Synel(name: "compatible_brands", type: (.u32, Synel.anyCount))
}

extension FileTypeBox: MP4Box {
    static let fourCC: FourCharCode = "ftyp"
    var isFullBox: Bool { get { return false } }
    
    func boxParse() -> MP4Parse {
        return
            parse(FileTypeBox.majorBrand) >-
            parse(FileTypeBox.minorVersion) >-
            parse(FileTypeBox.compatibleBrands)
    }
}

