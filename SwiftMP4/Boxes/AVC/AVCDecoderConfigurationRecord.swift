//
//  AVCDecoderConfigurationRecord.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.11..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct AVCDecoderConfigurationRecord {
    static let configurationVersion = Synel(name: "configurationVersion", type: (.u8, 1), defaultValue: .UInt8([1]))
    static let profileIndication = Synel(name: "AVCProfileIndication", type: (.u8, 1))
    static let profileCompatibility = Synel(name: "profile_compatibility", type: (.u8, 1))
    static let levelIndication = Synel(name: "AVCLevelIndication", type: (.u8, 1))
    static let lengthSizeMinusOne = Synel(name: "lengthSizeMinusOne", type: (.u8, 1))
    static let numberOfSequenceParameterSets = Synel(name: "numOfSequenceParameterSets", type: (.u8, 1))
    static let sequenceParameterSetLength = Synel(name: "sequenceParameterSetLength", type: (.u16, 1))
    static let sequenceParameterSetNALUnit = Synel(name: "sequenceParameterSetNALUnit", type: (.u8, Synel.anyCount))
    static let numberOfPictureParameterSets = Synel(name: "numOfPictureParameterSets", type: (.u8, 1))
    static let pictureParameterSetLength = Synel(name: "pictureParameterSetLength", type: (.u16, 1))
    static let pictureParameterSetNALUnit = Synel(name: "pictureParameterSetNALUnit", type: (.u8, Synel.anyCount))
    
    static func nalLengthSize(rawValue: UInt8) -> Int {
        return (Int(rawValue) & 0x03) + 1
    }
    
    static func sequenceParameterSetCount(rawValue: UInt8) -> Int {
        return Int(rawValue) & 0x1f
    }
    
    static func boxParse() -> MP4Parse {
        return
            parse(AVCDecoderConfigurationRecord.configurationVersion) >-
            parse(AVCDecoderConfigurationRecord.profileIndication) >-
            parse(AVCDecoderConfigurationRecord.profileCompatibility) >-
            parse(AVCDecoderConfigurationRecord.levelIndication) >-
            parse(AVCDecoderConfigurationRecord.lengthSizeMinusOne) >-
            parse(AVCDecoderConfigurationRecord.numberOfSequenceParameterSets) >-
            MP4Parse.get() >>-
            mp4Lambda { mps in
                let spsNum = mps.dictionary[AVCDecoderConfigurationRecord.numberOfSequenceParameterSets]![0].toU8s![0]
                let values = [Int](0..<self.sequenceParameterSetCount(spsNum))
                
                return
                    parseForEach(values) { _ in
                        parse(AVCDecoderConfigurationRecord.sequenceParameterSetLength) >-
                        MP4Parse.get() >>-
                        mp4Lambda { mps in
                            let spsLengths = mps.dictionary[AVCDecoderConfigurationRecord.sequenceParameterSetLength]!
                            let spsLength = Int(spsLengths[spsLengths.count - 1].toU16s![0])
                            let spsSynel = Synel(name: AVCDecoderConfigurationRecord.sequenceParameterSetNALUnit.name,
                                                 type: (.u8, spsLength))
                            
                            return parse(spsSynel)
                        }
                    }
            } >-
            parse(AVCDecoderConfigurationRecord.numberOfPictureParameterSets) >-
            MP4Parse.get() >>-
            mp4Lambda { mps in
                let ppsNum = Int(mps.dictionary[AVCDecoderConfigurationRecord.numberOfPictureParameterSets]![0].toU8s![0])
                let values = [Int](0..<ppsNum)
                
                return
                    parseForEach(values) { _ in
                        parse(AVCDecoderConfigurationRecord.pictureParameterSetLength) >-
                        MP4Parse.get() >>-
                        mp4Lambda { mps in
                            let ppsLengths = mps.dictionary[AVCDecoderConfigurationRecord.pictureParameterSetLength]!
                            let ppsLength = Int(ppsLengths[ppsLengths.count - 1].toU16s![0])
                            let ppsSynel = Synel(name: AVCDecoderConfigurationRecord.pictureParameterSetNALUnit.name,
                                                 type: (.u8, ppsLength))
                            
                            return parse(ppsSynel)
                        }
                    }
            }
    }
}

