//
//  SecondModel.swift
//  AIA
//
//  Created by Muhammad Faruuq Qayyum on 12/01/21.
//

import Foundation

struct DailyAdjusted: Hashable {
    let open1: String
    let low1: String
//    let date1: String?
    let date: Date?
    
    let open2: String
    let low2: String
    
    var identifier = UUID()
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
