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
    
    enum CodingKeys: String, CodingKey {
        case symbol = "1. symbol"
        case companyName = "2. name"
    }
}

struct Intraday: Decodable, Hashable {
    let open: String
    let high: String
    let low: String
    let date: String
    var identifier = UUID()
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

