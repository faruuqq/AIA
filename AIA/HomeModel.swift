//
//  HomeModel.swift
//  AIA
//
//  Created by Muhammad Faruuq Qayyum on 11/01/21.
//

import Foundation

struct HomeModel: Decodable, Hashable {
    let bestMatches: [BestMatches]
}

struct BestMatches: Decodable, Hashable {
    let symbol: String
    let companyName: String
    var identifier = UUID()
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    static func == (lhs: BestMatches, rhs: BestMatches) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    enum CodingKeys: String, CodingKey {
        case symbol = "1. symbol"
        case companyName = "2. name"
    }
}
