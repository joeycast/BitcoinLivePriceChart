//
//  BitcoinPriceViewModel.swift
//  Bitcoin Live Price Chart
//
//  Created by Joe Castagnaro on 11/22/24.
//

// BitcoinPriceViewModel.swift
import Foundation
import Combine

class BitcoinPriceViewModel: ObservableObject {
    @Published var prices: [BitcoinPrice] = []
    @Published var yAxisBounds: ClosedRange<Double> = 0...1
    @Published var currentTime: Date = Date()
    
    private var cancellables = Set<AnyCancellable>()
    private let webSocketManager = WebSocketManager()
    
    // Define the rolling window duration (10 minutes)
    private let rollingWindow: TimeInterval = 10 * 60 // 10 minutes in seconds
    
    // Define the sampling interval (10 seconds)
    private let samplingInterval: TimeInterval = 1 // 1 second
    
    init() {
        setupWebSocket()
        setupCurrentTimeUpdater()
    }
    
    private func setupWebSocket() {
        webSocketManager.$latestPrice
            .compactMap { $0 } // Filter out nil values
            .throttle(for: .seconds(samplingInterval), scheduler: RunLoop.main, latest: true) // Throttle to once every second
            .sink { [weak self] price in
                self?.addPrice(price)
            }
            .store(in: &cancellables)
        
        // Update yAxisBounds whenever prices change
        $prices
            .map { prices -> ClosedRange<Double> in
                guard let minPrice = prices.map({ $0.price }).min(),
                      let maxPrice = prices.map({ $0.price }).max(),
                      minPrice < maxPrice else {
                    return 0...1
                }
                let buffer = (maxPrice - minPrice) * 0.05
                let adjustedMin = floor((minPrice - buffer) / 100) * 100
                let adjustedMax = ceil((maxPrice + buffer) / 100) * 100
                return adjustedMin...adjustedMax
            }
            .receive(on: RunLoop.main)
            .assign(to: \.yAxisBounds, on: self)
            .store(in: &cancellables)
    }
    
    private func addPrice(_ price: Double) {
        let newPrice = BitcoinPrice(time: Date(), price: price)
        
        // Validate that the price's timestamp is not in the future
        if newPrice.time <= Date() {
            DispatchQueue.main.async { [weak self] in
                self?.prices.append(newPrice)
                self?.removeOldPrices()
                self?.sortPrices()
            }
        } else {
            print("Received a price with a future timestamp: \(newPrice.time)")
            // Optionally, handle this scenario (e.g., request data resend)
        }
    }
    
    private func removeOldPrices() {
        let cutoffDate = Date().addingTimeInterval(-rollingWindow)
        prices = prices.filter { $0.time >= cutoffDate }
    }
    
    private func sortPrices() {
        prices.sort { $0.time < $1.time }
    }
    
    private func setupCurrentTimeUpdater() {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] input in
                self?.currentTime = input
            }
            .store(in: &cancellables)
    }
    
    // NumberFormatter for price formatting
    let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency // Adds currency symbol and thousand separators
        formatter.locale = Locale(identifier: "en_US") // Set to US locale for USD
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    // DateFormatter for time labels
    let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short // e.g., "10:30 AM"
        formatter.dateStyle = .none
        return formatter
    }()
}
