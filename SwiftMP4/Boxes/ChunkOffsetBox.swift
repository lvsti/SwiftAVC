//
//  ChunkOffsetBox.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.07..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct ChunkOffsetBox {
    static let entryCount = Synel(name: "entry_count", type: (.u32, 1))
    static let chunkOffset = Synel(name: "chunk_offset", type: (.u32, 1))
}

extension ChunkOffsetBox: MP4Box {
    static let fourCC: FourCharCode = "stco"
    var isFullBox: Bool { get { return true } }
    
    func boxParse() -> MP4Parse {
        return
            parse(ChunkOffsetBox.entryCount) >-
            MP4Parse.get() >>-
            mp4Lambda { mps in
                let entryCount:Int = Int(mps.dictionary[ChunkOffsetBox.entryCount]![0].toU32s![0])
                let values = [Int](0..<entryCount)
                
                return
                    parseForEach(values) { _ in
                        parse(ChunkOffsetBox.chunkOffset)
                    }
            }
    }
}
