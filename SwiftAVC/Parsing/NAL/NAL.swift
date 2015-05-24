//
//  NAL.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.14..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

enum NALUnitType : Int {
    case Unspecified_0 = 0,
    SliceLayerNonIDR = 1,
    SliceDataA = 2,
    SliceDataB = 3,
    SliceDataC = 4,
    SliceLayerIDR = 5,
    SupplementalEnhancementInformation = 6,
    SequenceParameterSet = 7,
    PictureParameterSet = 8,
    AccessUnitDelimiter = 9,
    EndOfSequence = 10,
    EndOfStream = 11,
    FillerData = 12,
    SPSExtension = 13,
    Prefix = 14,
    SubsetSPS = 15,
    Reserved_16 = 16,
    Reserved_17 = 17,
    Reserved_18 = 18,
    SliceLayerAux = 19,
    SliceExtension = 20,
    SliceDepth = 21,
    Reserved_22 = 22,
    Reserved_23 = 23,
    Unspecified_24 = 24,
    Unspecified_25 = 25,
    Unspecified_26 = 26,
    Unspecified_27 = 27,
    Unspecified_28 = 28,
    Unspecified_29 = 29,
    Unspecified_30 = 30,
    Unspecified_31 = 31
}

extension NALUnitType: Printable {
    var description: String {
        get {
            let unspecifiedValues = [
                Unspecified_0,
                Unspecified_24,
                Unspecified_25,
                Unspecified_26,
                Unspecified_27,
                Unspecified_28,
                Unspecified_29,
                Unspecified_30,
                Unspecified_31
            ]

            let reservedValues = [
                Reserved_16,
                Reserved_17,
                Reserved_18,
                Reserved_22,
                Reserved_23,
            ]
            
            var name: String
            
            switch self {
            case SliceLayerNonIDR: name = "SliceLayerNonIDR"; break
            case SliceDataA: name = "SliceDataA"; break
            case SliceDataB: name = "SliceDataB"; break
            case SliceDataC: name = "SliceDataC"; break
            case SliceLayerIDR: name = "SliceLayerIDR"; break
            case SupplementalEnhancementInformation: name = "SupplementalEnhancementInformation"; break
            case SequenceParameterSet: name = "SequenceParameterSet"; break
            case PictureParameterSet: name = "PictureParameterSet"; break
            case AccessUnitDelimiter: name = "AccessUnitDelimiter"; break
            case EndOfSequence: name = "EndOfSequence"; break
            case EndOfStream: name = "EndOfStream"; break
            case FillerData: name = "FillerData"; break
            case SPSExtension: name = "SPSExtension"; break
            case Prefix: name = "Prefix"; break
            case SubsetSPS: name = "SubsetSPS"; break
            case SliceLayerAux: name = "SliceLayerAux"; break
            case SliceExtension: name = "SliceExtension"; break
            case SliceDepth: name = "SliceDepth"; break
            
            case _ where contains(unspecifiedValues, self):
                name = "Unspecified"
            case _ where contains(reservedValues, self):
                name = "Reserved"
                
            default:
                name = "Unknown"
            }
            
            return "\(name)(\(self.rawValue))"
        }
    }
}


struct NALUnit {
    let type: NALUnitType
    let refIDC: Int
    let svcHeader: SVCHeader?
    let mvcHeader: MVCHeader?
    let rbspBytes: NSData
    
    init(type: NALUnitType, refIDC: Int, rbspBytes: NSData, svcHeader: SVCHeader? = nil, mvcHeader: MVCHeader? = nil) {
        self.type = type
        self.refIDC = refIDC
        self.rbspBytes = rbspBytes
        self.svcHeader = svcHeader
        self.mvcHeader = mvcHeader
    }
}

extension NALUnit: Printable {
    var description: String { get { return "NAL {\(type): refIdc=\(refIDC), rbsp=\(rbspBytes.length)}" } }
}

typealias NALParse = EitherState<H264ParseError, H264ParseState, NALUnit>

func nalLambda(f: H264ParseState -> NALParse) -> (H264ParseState -> NALParse) {
    return f
}

// spec 7.4.1
struct NALUnitSynel {
    static let forbiddenZeroBit = Synel(name: "forbidden_zero_bit", type: .Fn(1)) { $0 == 0 }
    static let nalRefIDC = Synel(name: "nal_ref_idc", type: .Un(2))
    static let nalUnitType = Synel(name: "nal_unit_type", type: .Un(5))
    static let svcExtensionFlag = Synel(name: "svc_extension_flag", type: .Un(1))
}

// spec 7.3.1
func parseNALUnitBytes(bytes: NSData) -> Either<String, NALUnit> {
    let bs = Bitstream(data: bytes)
    let bps = BitParseState(bitstream: bs, offset: 0)
    let sdps = SDParseState(bitPS: bps, dictionary: SynelDictionary.empty())
    let hps = H264ParseState(parseState: sdps, context: H264Context())

    let nalParse =
        parseS(NALUnitSynel.forbiddenZeroBit) >-
        parseS(NALUnitSynel.nalRefIDC) >-
        parseS(NALUnitSynel.nalUnitType) >-
        H264Parse.get() >>-
        h264Lambda { hps in
            let nalType = NALUnitType(rawValue: hps.dictionary.scalar(forKey: NALUnitSynel.nalUnitType))!
            let extHeaderNALTypes: [NALUnitType] = [.Prefix, .SliceExtension, .SliceDepth]
            
            if !contains(extHeaderNALTypes, nalType) {
                return H264Parse.unit(())
            }
            
            return
                parseS(NALUnitSynel.svcExtensionFlag) >-
                H264Parse.get() >>-
                h264Lambda { hps in
                    let svcExtFlag = hps.dictionary.scalar(forKey: NALUnitSynel.svcExtensionFlag) != 0
                    return svcExtFlag ? parseNALUnitHeaderSVCExtension() : parseNALUnitHeaderMVCExtension()
                }
        } >-
        H264Parse.get() >>-
        nalLambda { hps in
            let bps = hps.bitParseState
            if bps.offset % 8 != 0 {
                return NALParse.fail("RBSP is not byte-aligned")
            }

            let byteOffset = bps.offset / 8

            let sd = hps.dictionary
            let nalType = sd.scalar(forKey: NALUnitSynel.nalUnitType)
            let refIDC = sd.scalar(forKey: NALUnitSynel.nalRefIDC)
            
            let escapedRBSPRange = NSMakeRange(byteOffset, bps.bitstream.length/8 - byteOffset)
            let rbspBytes = unescapeRBSP(bps.bitstream.data.subdataWithRange(escapedRBSPRange))

            let hasExtHeader = sd.hasKey(NALUnitSynel.svcExtensionFlag)
            var svcHeader: SVCHeader?
            var mvcHeader: MVCHeader?
            
            if hasExtHeader {
                if sd.scalar(forKey: NALUnitSynel.svcExtensionFlag) == 1 {
                    svcHeader = SVCHeader(synelDictionary: sd)
                } else {
                    mvcHeader = MVCHeader(synelDictionary: sd)
                }
            }

            let nalUnit = NALUnit(type: NALUnitType(rawValue: nalType)!,
                                  refIDC: refIDC,
                                  rbspBytes: rbspBytes,
                                  svcHeader: svcHeader,
                                  mvcHeader: mvcHeader)
            
            return NALParse.unit(nalUnit)
        }
    
    return nalParse.runH264Parse(hps).0
}

// spec 7.3.1
func unescapeRBSP(escapedBytes: NSData) -> NSData {
    let kEmulationPreventionSequence: [Byte] = [0, 0, 3];
    let epsData = NSData(bytes: UnsafePointer<Byte>(kEmulationPreventionSequence),
                         length: kEmulationPreventionSequence.count)
    
    var epsRange = escapedBytes.rangeOfData(epsData,
                                            options: NSDataSearchOptions(),
                                            range: NSMakeRange(0, escapedBytes.length))
    if epsRange.location == NSNotFound {
        return escapedBytes
    }
    
    var offset = 0
    let unescapedBytes = NSMutableData(capacity: escapedBytes.length)!
    
    while epsRange.location != NSNotFound {
        unescapedBytes.appendBytes(UnsafePointer<Byte>(escapedBytes.bytes).advancedBy(offset),
                                   length: epsRange.location + 2)
        offset += epsRange.location + 3
        epsRange = escapedBytes.rangeOfData(epsData,
                                            options: NSDataSearchOptions(),
                                            range: NSMakeRange(offset, escapedBytes.length - offset))
    }
    
    return unescapedBytes
}
