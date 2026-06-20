//
//  Item.swift
//  onivim3
//
//  Created by Teddy Malhan on 2026-06-20.
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
