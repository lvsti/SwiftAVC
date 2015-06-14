//
//  MP4.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.30..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation


struct MP4TempSynel {
    static let boxStartOffset = Synel(name: "tmp_boxStartOffset", type: (.u32, 1))
    static let stashedEndOffset = Synel(name: "tmp_stashedEndOffset", type: (.u32, 1))
}

let boxRegistry: [FourCharCode : MP4Box] = [
    FileTypeBox.fourCC: FileTypeBox(),
    MovieBox.fourCC: MovieBox(),
    MovieHeaderBox.fourCC: MovieHeaderBox(),
    TrackBox.fourCC: TrackBox(),
    TrackHeaderBox.fourCC: TrackHeaderBox(),
    HintTrackReferenceBox.fourCC: HintTrackReferenceBox(),
    DescriptionTrackReferenceBox.fourCC: DescriptionTrackReferenceBox(),
    HintDependencyTrackReferenceBox.fourCC: HintDependencyTrackReferenceBox(),
    VideoDepthTrackReferenceBox.fourCC: VideoDepthTrackReferenceBox(),
    VideoParallaxTrackReferenceBox.fourCC: VideoParallaxTrackReferenceBox(),
    TrackGroupBox.fourCC: TrackGroupBox(),
    MultiSourceTrackGroupTypeBox.fourCC: MultiSourceTrackGroupTypeBox(),
    MediaBox.fourCC: MediaBox(),
    MediaHeaderBox.fourCC: MediaHeaderBox(),
    HandlerReferenceBox.fourCC: HandlerReferenceBox(),
    MediaInformationBox.fourCC: MediaInformationBox(),
    VideoMediaHeaderBox.fourCC: VideoMediaHeaderBox(),
    SoundMediaHeaderBox.fourCC: SoundMediaHeaderBox(),
    HintMediaHeaderBox.fourCC: HintMediaHeaderBox(),
    NullMediaHeaderBox.fourCC: NullMediaHeaderBox(),
    MediaDataBox.fourCC: MediaDataBox(),
    EditBox.fourCC: EditBox(),
    EditListBox.fourCC: EditListBox(),
    SampleTableBox.fourCC: SampleTableBox(),
    SampleSizeBox.fourCC: SampleSizeBox(),
    ChunkOffsetBox.fourCC: ChunkOffsetBox(),
    SampleDescriptionBox.fourCC: SampleDescriptionBox(),
    AVCSampleEntry.fourCC: AVCSampleEntry(),
    AVCConfigurationBox.fourCC: AVCConfigurationBox()
]



func parseBox() -> MP4Parse {
    return
        MP4Parse.get() >>-
        mp4Lambda { mps in
            let newMPS = mps.addingValue(SynelValue.UInt32([UInt32(mps.offset)]), forKey: MP4TempSynel.boxStartOffset)
            return MP4Parse.put(newMPS)
        } >-
        Box.boxParse() >-
        MP4Parse.get() >>-
        mp4Lambda { mps in
            let size = mps.dictionary[Box.size]![0].toU32s![0]
            let lastBoxStartOffset = Int(mps.dictionary[MP4TempSynel.boxStartOffset]![0].toU32s![0])

            let hasLargeSize = (size == 1)
            let extendsToEOF = (size == 0)
            
            var frameRange = NSMakeRange(lastBoxStartOffset, 0)
            
            if hasLargeSize {
                let largeSize = mps.dictionary[Box.largeSize]![0].toU64s![0]
                frameRange.length = Int(largeSize)
            } else if extendsToEOF {
                frameRange.length = mps.data.length - frameRange.location
            } else {
                frameRange.length = Int(size)
            }

            let newMPS = mps
                .withEndOffset(NSMaxRange(frameRange))
                .addingValue(SynelValue.UInt32([UInt32(mps.endOffset)]), forKey: MP4TempSynel.stashedEndOffset)
            return MP4Parse.put(newMPS)
        } >-
        MP4Parse.get() >>-
        mp4Lambda { mps in
            let type = mps.dictionary[Box.type]![0].toU32s![0]
            if let box = boxRegistry[type] {
                if box.isFullBox {
                    return FullBox.boxParse() >- box.boxParse()
                }
                return box.boxParse()
            }
            return MP4Parse.unit(())
        } >-
        MP4Parse.get() >>-
        mp4Lambda { mps in
            let type = mps.dictionary[Box.type]![0].toU32s![0]
            let lastBoxStartOffset = Int(mps.dictionary[MP4TempSynel.boxStartOffset]![0].toU32s![0])
            let frameRange = NSMakeRange(lastBoxStartOffset, mps.endOffset - lastBoxStartOffset)
            let payloadRange = NSMakeRange(mps.offset, mps.endOffset - mps.offset)
            var children: [BoxDescriptor] = []
            
            let isKnownBoxType = boxRegistry[type] != nil

            if payloadRange.length > 0 && isKnownBoxType {
                // nonempty and known box, parse contents
                let payloadMPS = MP4ParseState(data: mps.data,
                                               offset: payloadRange.location,
                                               endOffset: NSMaxRange(payloadRange))
                let (ppResult, ppState) = parseBoxes().runMP4Parse(payloadMPS)
                switch (ppResult) {
                case .Left(let errorBox):
                    let type = mps.dictionary[Box.type]![0].toU32s![0]
                    return MP4Parse.fail("failed to parse payload of '\(FourCharCode.toString(type))': \(errorBox.unwrap())")
                case .Right(_): children = ppState.boxes
                }
            }
            
            let box = BoxDescriptor(properties: mps.dictionary,
                                    frameRange: frameRange,
                                    payloadRange: payloadRange,
                                    children: children)

            let stashedEndOffset = Int(mps.dictionary[MP4TempSynel.stashedEndOffset]![0].toU32s![0])
            let newMPS = mps.committingBox(box).withEndOffset(stashedEndOffset)
            
            return MP4Parse.put(newMPS)
        }
}

func parseIf(predicate: MP4ParseState -> Bool, parse: () -> MP4Parse) -> MP4Parse {
    return
        MP4Parse.get() >>-
        mp4Lambda { mps in
            predicate(mps) ? parse() : MP4Parse.unit(())
        }
}

func parseForEach<A>(values: [A], parser: A -> MP4Parse) -> MP4Parse {
    var chain = MP4Parse.unit(())
    
    for value in values {
        chain = chain >- parser(value)
    }
    
    return chain
}

func parseWhile(predicate: MP4ParseState -> Bool, parse: () -> MP4Parse) -> MP4Parse {
    return
        MP4Parse.get() >>-
        mp4Lambda { mps in
            if !predicate(mps) {
                return MP4Parse.unit(())
            }
            return parse() >- parseWhile(predicate, parse)
        }
}

func parseBoxes() -> MP4Parse {
    return
        parseWhile({ mps in mps.offset < mps.endOffset }) {
            parseBox()
        }
}


public func parseMP4Data(data: NSData) -> Either<MP4ParseError, [BoxDescriptor]> {
    let mps = MP4ParseState(data: data)
    let (result, state) = parseBoxes().runMP4Parse(mps)
    switch result {
    case .Left(let errorBox): return .Left(errorBox)
    case .Right(_): return .Right(Wrap(state.boxes))
    }
}

public func getAVCVideoTrackBoxes(boxes: [BoxDescriptor]) -> [BoxDescriptor] {
    return boxes
        .filter { $0.type == MovieBox.fourCC }
        .map { $0.children }
        .reduce([], +)
        .filter { $0.type == TrackBox.fourCC }
        .filter { trackBox in
            let mediaBox = trackBox.children.filter { $0.type == MediaBox.fourCC } [0]
            let handlerBox = mediaBox.children.filter { $0.type == HandlerReferenceBox.fourCC } [0]
            let isVideo = handlerBox.properties[HandlerReferenceBox.handlerType]![0].toU32s![0] ==
                            HandlerReferenceBox.HandlerType.Video.rawValue
            if !isVideo {
                return false
            }
            
            let sampleDescBox = mediaBox.children
                .filter { $0.type == MediaInformationBox.fourCC } [0].children
                .filter { $0.type == SampleTableBox.fourCC } [0].children
                .filter { $0.type == SampleDescriptionBox.fourCC } [0]
            
            let isAVC = contains(sampleDescBox.children) { $0.type == AVCSampleEntry.fourCC }
            return isAVC
        }
}

func zip<A, B>(s0: [A], s1: [B]) -> [(A, B)] {
    var zipped = [(A,B)]()
    for i in 0..<min(s0.count, s1.count) {
        zipped.append((s0[i], s1[i]))
    }
    return zipped
}

public func getAVCNALLengthSize(trackBox: BoxDescriptor) -> Int {
    let sampleTableBox = trackBox.children
        .filter { $0.type == MediaBox.fourCC } [0].children
        .filter { $0.type == MediaInformationBox.fourCC } [0].children
        .filter { $0.type == SampleTableBox.fourCC } [0]
    
    let avcConfigBox = sampleTableBox.children
        .filter { $0.type == SampleDescriptionBox.fourCC } [0].children
        .filter { $0.type == AVCSampleEntry.fourCC } [0].children
        .filter { $0.type == AVCConfigurationBox.fourCC } [0]
    
    let lsmo = avcConfigBox.properties[AVCDecoderConfigurationRecord.lengthSizeMinusOne]![0].toU8s![0]
    return AVCDecoderConfigurationRecord.nalLengthSize(lsmo)
}

func octetFrame(size: Int, payloadLength: Int) -> [UInt8] {
    var frameBytes = [UInt8]()
    for i in 0..<size {
        let byte = UInt8((payloadLength >> (8 * (size - i - 1))) & 0xff)
        frameBytes.append(byte)
    }
    return frameBytes
}

public func getAVCParameterSets(trackBox: BoxDescriptor) -> [NSData] {
    let sampleTableBox = trackBox.children
        .filter { $0.type == MediaBox.fourCC } [0].children
        .filter { $0.type == MediaInformationBox.fourCC } [0].children
        .filter { $0.type == SampleTableBox.fourCC } [0]

    let avcConfigBox = sampleTableBox.children
        .filter { $0.type == SampleDescriptionBox.fourCC } [0].children
        .filter { $0.type == AVCSampleEntry.fourCC } [0].children
        .filter { $0.type == AVCConfigurationBox.fourCC } [0]
    
    let lsmo = avcConfigBox.properties[AVCDecoderConfigurationRecord.lengthSizeMinusOne]![0].toU8s![0]
    let nalLengthSize = AVCDecoderConfigurationRecord.nalLengthSize(lsmo)
    
    var parameterSets = [NSData]()
    
    let spsNALUnits = avcConfigBox.properties[AVCDecoderConfigurationRecord.sequenceParameterSetNALUnit]!
    for i in 0..<spsNALUnits.count {
        let spsOctets = spsNALUnits[i].toU8s!
        let framedSPSOctets = octetFrame(nalLengthSize, spsOctets.count) + spsOctets
        let spsData = NSData(bytes: framedSPSOctets, length: framedSPSOctets.count)
        parameterSets.append(spsData)
    }

    let ppsNALUnits = avcConfigBox.properties[AVCDecoderConfigurationRecord.pictureParameterSetNALUnit]!
    for i in 0..<ppsNALUnits.count {
        let ppsOctets = ppsNALUnits[i].toU8s!
        let framedPPSOctets = octetFrame(nalLengthSize, ppsOctets.count) + ppsOctets
        let ppsData = NSData(bytes: framedPPSOctets, length: framedPPSOctets.count)
        parameterSets.append(ppsData)
    }
    
    return parameterSets
}

public func getTrackSampleDataRanges(trackBox: BoxDescriptor) -> [NSRange] {
    let sampleTableBox = trackBox.children
        .filter { $0.type == MediaBox.fourCC } [0].children
        .filter { $0.type == MediaInformationBox.fourCC } [0].children
        .filter { $0.type == SampleTableBox.fourCC } [0]
    
    let sampleSizes: [Int] = sampleTableBox.children
        .filter { $0.type == SampleSizeBox.fourCC }
        .map { ssb in
            let size = Int(ssb.properties[SampleSizeBox.sampleSize]![0].toU32s![0])
            if size == 0 {
                return ssb.properties[SampleSizeBox.entrySize]!
                    .map { Int($0.toU32s![0]) }
            }
            
            let count: Int = Int(ssb.properties[SampleSizeBox.sampleCount]![0].toU32s![0])
            return [Int](count: count, repeatedValue: size)
        }
        .reduce([], +)

    let chunkOffsets: [Int] = sampleTableBox.children
        .filter { $0.type == ChunkOffsetBox.fourCC }
        .map { cob in
            let count = Int(cob.properties[ChunkOffsetBox.entryCount]![0].toU32s![0])
            return cob.properties[ChunkOffsetBox.chunkOffset]!
                .map { Int($0.toU32s![0]) }
        }
        .reduce([], +)

    assert(sampleSizes.count == chunkOffsets.count,
        "sample size - chunk offset count mismatch: \(sampleSizes.count) <> \(chunkOffsets.count)")
    
    return zip(chunkOffsets, sampleSizes)
        .map { NSMakeRange($0, $1) }
}



