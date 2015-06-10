//
//  SampleSizeBox.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.07..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct SampleSizeBox {
    static let sampleSize = Synel(name: "sample_size", type: (.u32, 1))
    static let sampleCount = Synel(name: "sample_count", type: (.u32, 1))
    static let entrySize = Synel(name: "entry_size", type: (.u32, 1))
}

extension SampleSizeBox: MP4Box {
    static let fourCC: FourCharCode = "stsz"
    var isFullBox: Bool { get { return true } }
    
    func boxParse() -> MP4Parse {
        return
            parse(SampleSizeBox.sampleSize) >-
            parse(SampleSizeBox.sampleCount) >-
            parseIf({ mps in mps.dictionary[SampleSizeBox.sampleSize]![0].toU32s![0] == 0 }) {
                MP4Parse.get() >>-
                mp4Lambda { mps in
                    let sampleCount:Int = Int(mps.dictionary[SampleSizeBox.sampleCount]![0].toU32s![0])
                    let values = [Int](0..<sampleCount)
                    
                    return
                        parseForEach(values) { _ in
                            parse(SampleSizeBox.entrySize)
                        }
                }
            }
    }
}
