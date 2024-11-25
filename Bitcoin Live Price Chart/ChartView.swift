//
//  ChartView.swift
//  Bitcoin Live Price Chart
//
//  Created by Joe Castagnaro on 11/24/24.
//


// ChartView.swift
import SwiftUI
import Charts

struct ChartView: View, Equatable {
    @ObservedObject var viewModel: BitcoinPriceViewModel
    
    static func == (lhs: ChartView, rhs: ChartView) -> Bool {
        return lhs.viewModel.prices == rhs.viewModel.prices &&
               lhs.viewModel.yAxisBounds == rhs.viewModel.yAxisBounds &&
               lhs.viewModel.currentTime == rhs.viewModel.currentTime
    }
    
    // Shared NumberFormatter for price formatting
    private let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency // Adds currency symbol and thousand separators
        formatter.locale = Locale(identifier: "en_US") // Set to US locale for USD
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var body: some View {
        Chart(viewModel.prices) { price in
            // AreaMark for the gradient fill
            AreaMark(
                x: .value("Time", price.time),
                yStart: .value("Min Price", viewModel.yAxisBounds.lowerBound),
                yEnd: .value("Price", price.price)
            )
            .interpolationMethod(.catmullRom) // Smooth interpolation
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.2), Color.orange.opacity(0)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // LineMark for the price line
            LineMark(
                x: .value("Time", price.time),
                y: .value("Price", price.price)
            )
            .interpolationMethod(.catmullRom) // Smooth interpolation
            .foregroundStyle(Color.orange)
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .stride(by: 100)) { value in
                if let price = value.as(Double.self) {
                    // Format Y-axis labels with currency formatting
                    AxisValueLabel("\(priceFormatter.string(from: NSNumber(value: price)) ?? "$\(price)")")
                        .font(.caption2)
                }
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.3)) // Horizontal grid lines
            }
        }
        .chartYScale(domain: viewModel.yAxisBounds) // Dynamic Y-axis scale
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
        .chartXScale(domain: getXAxisDomain()) // Dynamic x-axis scale based on current data
        .frame(maxWidth: .infinity, alignment: .leading) // Align Chart to leading side
        .padding([.leading, .trailing])
    }
    
    // Updated function to determine the x-axis domain based on available data
    private func getXAxisDomain() -> ClosedRange<Date> {
        guard let firstPriceTime = viewModel.prices.first?.time else {
            // If no data, default to current time
            let now = viewModel.currentTime
            return now...now
        }
        
        let tenMinutesAgo = viewModel.currentTime.addingTimeInterval(-10 * 60) // 10 minutes ago
        
        // Determine the tentative start time
        let tentativeStartTime = firstPriceTime > tenMinutesAgo ? firstPriceTime : tenMinutesAgo
        
        // Ensure startTime does not exceed endTime
        let startTime = tentativeStartTime <= viewModel.currentTime ? tentativeStartTime : viewModel.currentTime
        let endTime = viewModel.currentTime
        
        return startTime...endTime
    }
    
    // Formatter for the x-axis time labels
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short // e.g., "10:30 AM"
        formatter.dateStyle = .none
        return formatter
    }()
}
