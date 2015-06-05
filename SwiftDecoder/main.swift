//
//  main.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.06..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

func processNALParseResult(result: Either<String, NALUnit>) -> () {
    switch result {
    case .Left(let error):
        println("ERROR: \(error.unbox())")
    case .Right(let nalUnitBox):
        println("decoding \(nalUnitBox.unbox())")
    }
}


let data: NSData = NSData(contentsOfFile: Process.arguments[1])!

nalUnitRangesFromByteStream(data)
    .map { data.subdataWithRange($0) }
    .map { parseNALUnitBytes($0) }
    .map(processNALParseResult)

