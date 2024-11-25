//
//  ContentView.swift
//  Bitcoin Live Price Chart
//
//  Created by Joe Castagnaro on 11/22/24.
//

// ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = BitcoinPriceViewModel()
    
    var body: some View {
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
                        VStack {
                            Text("\(viewModel.priceFormatter.string(from: NSNumber(value: latestPrice.price)) ?? "$\(latestPrice.price)")")
                                .font(.title)
                                .accessibilityLabel("Current Bitcoin Price: \(latestPrice.price)")
//                            Text("Last updated at \(latestPrice.time, formatter: viewModel.timeFormatter)")
//                                .font(.caption)
//                                .foregroundColor(.gray)
                        }
                    } else {
                        Text("Loading...")
                            .font(.title)
                            .accessibilityLabel("Loading Bitcoin Price")
                    }
                }
                .padding(.bottom, 35)
                
                // Chart Section
                if !viewModel.prices.isEmpty {
                    ChartView(viewModel: viewModel)
                        .transition(.opacity) // Smooth transition when data updates
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
                
                // Clock View to Display Current Time
//                ClockView(viewModel: viewModel)
//                    .padding(.top, 10)
                
                Spacer()
            }
            .padding()
            .foregroundColor(.white) // Ensure text is visible against the background
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
