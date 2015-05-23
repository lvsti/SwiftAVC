//
//  Utils.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.11..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

func extendSign(value: Int, bitWidth: Int) -> Int {
    let signBit: Int = 1 << (bitWidth-1)
    let isNegative = value & signBit != 0
    
    return isNegative ? (-1 & (value & (signBit-1))) : value
}

