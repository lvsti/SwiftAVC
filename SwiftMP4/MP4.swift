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
    ChunkOffsetBox.fourCC: ChunkOffsetBox()
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
