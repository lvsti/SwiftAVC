//
//  VUI.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.27..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

// -----------------------------------------------------------------------------
// Video Usability Information (spec Annex E)
// -----------------------------------------------------------------------------

struct VUIAspectRatio {
    static let unspecified = 0
    static let extendedSAR = 255
}


// spec E.2.1
struct VUISynel {
    static let aspectRatioInfoPresentFlag = Synel(name: "aspect_ratio_info_present_flag", type: .Un(1), categories: [0])
    static let aspectRatioIDC = Synel(name: "aspect_ratio_idc", type: .Un(8), categories: [0])
    static let sarWidth = Synel(name: "sar_width", type: .Un(16), categories: [0])
    static let sarHeight = Synel(name: "sar_height", type: .Un(16), categories: [0])
    static let overscanInfoPresentFlag = Synel(name: "overscan_info_present_flag", type: .Un(1), categories: [0])
    static let overscanAppropriateFlag = Synel(name: "overscan_appropriate_flag", type: .Un(1), categories: [0])
    static let videoSignalTypePresentFlag = Synel(name: "video_signal_type_present_flag", type: .Un(1), categories: [0])
    static let videoFormat = Synel(name: "video_format", type: .Un(3), categories: [0])
    static let videoFullRangeFlag = Synel(name: "video_full_range_flag", type: .Un(1), categories: [0])
    static let colourDescriptionPresentFlag = Synel(name: "colour_description_present_flag", type: .Un(1), categories: [0])
    static let colourPrimaries = Synel(name: "colour_primaries", type: .Un(8), categories: [0])
    static let transferCharacteristics = Synel(name: "transfer_characteristics", type: .Un(8), categories: [0])
    static let matrixCoefficients = Synel(name: "matrix_coefficients", type: .Un(8), categories: [0])
    static let chromaLocInfoPresentFlag = Synel(name: "chroma_loc_info_present_flag", type: .Un(1), categories: [0])
    static let chromaSampleLocTypeTopField = Synel(name: "chroma_sample_loc_type_top_field", type: .UEv, categories: [0]) { $0 <= 5 }
    static let chromaSampleLocTypeBottomField = Synel(name: "chroma_sample_loc_type_bottom_field", type: .UEv, categories: [0]) { $0 <= 5 }
    static let timingInfoPresentFlag = Synel(name: "timing_info_present_flag", type: .Un(1), categories: [0])
    static let numUnitsInTick = Synel(name: "num_units_in_tick", type: .Un(32), categories: [0])
    static let timeScale = Synel(name: "time_scale", type: .Un(32), categories: [0])
    static let fixedFrameRateFlag = Synel(name: "fixed_frame_rate_flag", type: .Un(1), categories: [0])
    static let nalHRDParametersPresentFlag = Synel(name: "nal_hrd_parameters_present_flag", type: .Un(1), categories: [0])
    static let vclHRDParametersPresentFlag = Synel(name: "vcl_hrd_parameters_present_flag", type: .Un(1), categories: [0])
    static let lowDelayHRDFlag = Synel(name: "low_delay_hrd_flag", type: .Un(1), categories: [0])
    static let picStructPresentFlag = Synel(name: "pic_struct_present_flag", type: .Un(1), categories: [0])
    static let bitstreamRestrictionFlag = Synel(name: "bitstream_restriction_flag", type: .Un(1), categories: [0])
    static let motionVectorsOverPicBoundariesFlag = Synel(name: "motion_vectors_over_pic_boundaries_flag", type: .Un(1), categories: [0])
    static let maxBytesPerPicDenom = Synel(name: "max_bytes_per_pic_denom", type: .UEv, categories: [0]) { $0 <= 16 }
    static let maxBitsPerMBDenom = Synel(name: "max_bits_per_mb_denom", type: .UEv, categories: [0]) { $0 <= 16 }
    static let log2MaxMVLengthHorizontal = Synel(name: "log2_max_mv_length_horizontal", type: .UEv, categories: [0]) { $0 <= 16 }
    static let log2MaxMVLengthVertical = Synel(name: "log2_max_mv_length_vertical", type: .UEv, categories: [0]) { $0 <= 16 }
    static let maxNumReorderFrames = Synel(name: "max_num_reorder_frames", type: .UEv, categories: [0]) // (<=max_dec_frame_buffering)
    static let maxDecFrameBuffering = Synel(name: "max_dec_frame_buffering", type: .UEv, categories: [0]) // (>=max_num_ref_frames)
}

func parseVUIParameters() -> H264Parse {
    return
        parseS(VUISynel.aspectRatioInfoPresentFlag) >-
        parseIfSD({ sd in sd.scalar(forKey: VUISynel.aspectRatioInfoPresentFlag) != 0 }) {
            parseS(VUISynel.aspectRatioIDC) >-
            parseIfSD({ sd in sd.scalar(forKey: VUISynel.aspectRatioIDC) == VUIAspectRatio.extendedSAR }) {
                parseS(VUISynel.sarWidth) >-
                parseS(VUISynel.sarHeight)
            }
        } >-
        parseS(VUISynel.overscanInfoPresentFlag) >-
        parseIfSD({ sd in sd.scalar(forKey: VUISynel.overscanInfoPresentFlag) != 0 }) {
            parseS(VUISynel.overscanAppropriateFlag)
        } >-
        parseS(VUISynel.videoSignalTypePresentFlag) >-
        parseIfSD({ sd in sd.scalar(forKey: VUISynel.videoSignalTypePresentFlag) != 0 }) {
            parseS(VUISynel.videoFormat) >-
            parseS(VUISynel.videoFullRangeFlag) >-
            parseS(VUISynel.colourDescriptionPresentFlag) >-
            parseIfSD({ sd in sd.scalar(forKey: VUISynel.colourDescriptionPresentFlag) != 0 }) {
                parseS(VUISynel.colourPrimaries) >-
                parseS(VUISynel.transferCharacteristics) >-
                parseS(VUISynel.matrixCoefficients)
            }
        } >-
        parseS(VUISynel.chromaLocInfoPresentFlag) >-
        parseIfSD({ sd in sd.scalar(forKey: VUISynel.chromaLocInfoPresentFlag) != 0 }) {
            parseS(VUISynel.chromaSampleLocTypeTopField) >-
            parseS(VUISynel.chromaSampleLocTypeBottomField)
        } >-
        parseS(VUISynel.timingInfoPresentFlag) >-
        parseIfSD({ sd in sd.scalar(forKey: VUISynel.timingInfoPresentFlag) != 0 }) {
            parseS(VUISynel.numUnitsInTick) >-
            parseS(VUISynel.timeScale) >-
            parseS(VUISynel.fixedFrameRateFlag)
        } >-
        parseS(VUISynel.nalHRDParametersPresentFlag) >-
        parseIfSD({ sd in sd.scalar(forKey: VUISynel.nalHRDParametersPresentFlag) != 0 }) {
            parseHRDParameters()
        } >-
        parseS(VUISynel.vclHRDParametersPresentFlag) >-
        parseIfSD({ sd in sd.scalar(forKey: VUISynel.vclHRDParametersPresentFlag) != 0 }) {
            // TODO: what if both VCL and NAL HRD parameters are present?
            parseHRDParameters()
        } >-
        parseIfSD({ sd in sd.scalar(forKey: VUISynel.nalHRDParametersPresentFlag) != 0 ||
                          sd.scalar(forKey: VUISynel.vclHRDParametersPresentFlag) != 0 }) {
            parseS(VUISynel.lowDelayHRDFlag)
        } >-
        parseS(VUISynel.picStructPresentFlag) >-
        parseS(VUISynel.bitstreamRestrictionFlag) >-
        parseIfSD({ sd in sd.scalar(forKey: VUISynel.bitstreamRestrictionFlag) != 0 }) {
            parseS(VUISynel.motionVectorsOverPicBoundariesFlag) >-
            parseS(VUISynel.maxBytesPerPicDenom) >-
            parseS(VUISynel.maxBitsPerMBDenom) >-
            parseS(VUISynel.log2MaxMVLengthHorizontal) >-
            parseS(VUISynel.log2MaxMVLengthVertical) >-
            parseS(VUISynel.maxNumReorderFrames) >-
            parseS(VUISynel.maxDecFrameBuffering)
        }
}


