//
//  ContentView.swift
//  Bitcoin Live Price Chart
//
//  Created by Joe Castagnaro on 11/22/24.
//

// ContentView.swift
import SwiftUI
import Charts
import Combine

struct ContentView: View {
    @StateObject private var viewModel = BitcoinPriceViewModel()
    
    // Define the rolling window duration (10 minutes)
    private let rollingWindow: TimeInterval = 10 * 60 // 10 minutes in seconds
    
    // Shared NumberFormatter for price formatting
    private let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency // Adds currency symbol and thousand separators
        formatter.locale = Locale(identifier: "en_US") // Set to US locale for USD
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    // Computed property to determine startTime
    private var startTime: Date {
        let currentTime = self.currentTime // Use the synchronized currentTime
        guard let earliestTime = viewModel.prices.map({ $0.time }).min() else {
            print("No prices available. Setting startTime to currentTime: \(currentTime)")
            return currentTime
        }
        let timeDifference = currentTime.timeIntervalSince(earliestTime)
        let calculatedStartTime = timeDifference > rollingWindow ? currentTime.addingTimeInterval(-rollingWindow) : earliestTime
        
        // Ensure startTime does not exceed currentTime minus 1 second to prevent zero-length range
        var safeStartTime = calculatedStartTime <= currentTime.addingTimeInterval(-1) ? calculatedStartTime : currentTime.addingTimeInterval(-1)
        
        // Additional safeguard: Ensure safeStartTime <= currentTime
        if safeStartTime > currentTime {
            print("Adjusted safeStartTime from \(safeStartTime) to \(currentTime) to maintain range integrity.")
            safeStartTime = currentTime
        }
        
        // Final check to ensure startTime <= currentTime
        assert(safeStartTime <= currentTime, "startTime (\(safeStartTime)) exceeds currentTime (\(currentTime)).")
        
        print("Computed startTime: \(safeStartTime), currentTime: \(currentTime)")
        
        return safeStartTime
    }
    
    // Computed property for dynamic Y-axis bounds with buffer
    private var yAxisBounds: ClosedRange<Double> {
        let prices = viewModel.prices.map { $0.price }
        guard let minPrice = prices.min(),
              let maxPrice = prices.max(),
              minPrice < maxPrice else {
            // Prevent invalid range; default to 0-1 if all prices are equal
            return 0...1
        }
        let buffer = (maxPrice - minPrice) * 0.05
        return (minPrice - buffer)...(maxPrice + buffer)
    }
    
    // State property for current time to update "Now" line
    @State private var currentTime: Date = Date()
    
    // State property for Combine's Timer publisher
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        ZStack {
            
            NavigationView {
                VStack(spacing: 20) {
                    // Header with Bitcoin Logo and Center-Aligned Price
                    HStack {
                        // Bitcoin Logo (Left-Aligned)
                        Image("bitcoin-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100) // Adjust size as needed
                            .padding(.leading)
                            .accessibilityLabel("Bitcoin Logo") // Accessibility Enhancement
                        
                        Spacer()
                        
                        // Bitcoin Price (Center-Aligned)
                        if let latestPrice = viewModel.prices.last {
                            Text("\(priceFormatter.string(from: NSNumber(value: latestPrice.price)) ?? "$\(latestPrice.price)")")
                                .font(.title)
                                .accessibilityLabel("Current Bitcoin Price: \(latestPrice.price)")
                        } else {
                            Text("Loading...")
                                .font(.title)
                                .accessibilityLabel("Loading Bitcoin Price")
                        }
                    }
                    
                    // Chart Section
                    if !viewModel.prices.isEmpty {
                        Chart {
                            // Line representing Bitcoin price over time
                            ForEach(viewModel.prices) { price in
                                LineMark(
                                    x: .value("Time", price.time),
                                    y: .value("Price", price.price)
                                )
                                .interpolationMethod(.linear)
                                .foregroundStyle(Color.orange)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                if let price = value.as(Double.self) {
                                    // Format Y-axis labels with currency formatting
                                    AxisValueLabel("\(priceFormatter.string(from: NSNumber(value: price)) ?? "$\(price)")")
                                        .font(.caption2)
                                }
                                AxisGridLine()
                                    .foregroundStyle(Color.gray.opacity(0.3)) // Horizontal grid lines
                            }
                        }
                        .chartYScale(domain: yAxisBounds) // Dynamic Y-axis scale
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .minute, count: 1)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel("\(date, formatter: timeFormatter)")
                                        .font(.caption2)
                                }
                                AxisGridLine()
                                    .foregroundStyle(Color.gray.opacity(0.3)) // Vertical grid lines
                            }
                        }
                        .chartXScale(domain: startTime...currentTime) // Dynamic x-axis scale
                        .chartOverlay { proxy in
                            GeometryReader { geometry in
                                Rectangle().fill(Color.clear).contentShape(Rectangle())
                            }
                        }
                        .animation(.easeInOut, value: viewModel.prices.count) // Smooth transitions
                        .onAppear {
                            // Start a Combine Timer to update currentTime every second
                            Timer.publish(every: 1, on: .main, in: .common)
                                .autoconnect()
                                .sink { input in
                                    self.currentTime = input
                                }
                                .store(in: &cancellables)
                        }
                        .padding([.leading, .trailing])
                    } else {
                        // Placeholder for when there are no prices
                        VStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                                .padding()
                            
                            Text("No data available")
                                .font(.title2)
                                .foregroundColor(.gray)
                                .accessibilityLabel("No Bitcoin price data available")
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
                .padding()
                .foregroundColor(.white)
            }
        }
    }
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
    
    // Formatter for the x-axis time labels
    let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short // e.g., "10:30 AM"
        formatter.dateStyle = .none
        return formatter
    }()
}
