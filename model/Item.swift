//
//  Item.swift
//  model
//
//  Created by shuruq alshammari on 03/09/1446 AH.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
