//
//  BitcoinPrice.swift
//  Bitcoin Live Price Chart
//
//  Created by Joe Castagnaro on 11/22/24.
//

import Foundation

struct BitcoinPrice: Identifiable {
    let id = UUID()
    let time: Date
    let price: Double
}
