//
//  BitcoinPriceViewModel.swift
//  Bitcoin Live Price Chart
//
//  Created by Joe Castagnaro on 11/22/24.
//

import Foundation
import Combine

class BitcoinPriceViewModel: ObservableObject {
    @Published var prices: [BitcoinPrice] = []
    private var cancellables = Set<AnyCancellable>()
    private let webSocketManager = WebSocketManager()
    
    // Define the rolling window duration (10 minutes)
    private let rollingWindow: TimeInterval = 10 * 60 // 10 minutes in seconds
    
    init() {
        webSocketManager.$latestPrice
            .compactMap { $0 }
            .sink { [weak self] price in
                self?.addPrice(price)
            }
            .store(in: &cancellables)
    }
    
    private func addPrice(_ price: Double) {
        let newPrice = BitcoinPrice(time: Date(), price: price)
        
        // Validate that the price's timestamp is not in the future
        if newPrice.time <= Date() {
            prices.append(newPrice)
            removeOldPrices()
        } else {
            print("Received a price with a future timestamp: \(newPrice.time)")
            // Optionally, handle this scenario (e.g., request data resend)
        }
    }
    
    private func removeOldPrices() {
        let cutoffDate = Date().addingTimeInterval(-rollingWindow)
        prices = prices.filter { $0.time >= cutoffDate }
    }
}
