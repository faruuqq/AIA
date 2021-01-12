//
//  SecondModel.swift
//  AIA
//
//  Created by Muhammad Faruuq Qayyum on 12/01/21.
//

import Foundation

struct DailyAdjusted: Hashable {
    let open: String
    let low: String
    let date: String
    var identifier = UUID()
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
