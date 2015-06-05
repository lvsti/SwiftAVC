//
//  AppDelegate.swift
//  SwiftDecoder
//
//  Created by Tamas Lustyik on 2015.06.05..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Cocoa
import SwiftMP4

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!


    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        doit()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


    func doit() {
        let data: NSData = NSData(contentsOfFile: Process.arguments[1])!
        //
        //nalUnitRangesFromByteStream(data)
        //    .map { data.subdataWithRange($0) }
        //    .map { parseNALUnitBytes($0) }
        //    .map(processNALParseResult)
        
        let eitherBoxes = SwiftMP4.parseMP4Data(data)
        switch eitherBoxes {
        case .Left(let errorBox):
            println("MPEG parsing failed: \(errorBox.unbox())")
            break
            
        case .Right(let valueBox):
            let boxes = valueBox.unbox()
            boxes.map { println("\($0.type): frame \($0.frameRange), payload \($0.payloadRange)") }
            break
        }

    }
    
}

