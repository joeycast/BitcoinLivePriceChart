// ChartView.swift
import SwiftUI
import Charts

struct ChartView: View {
    @ObservedObject var viewModel: BitcoinPriceViewModel
    
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
            .interpolationMethod(.linear) // Retain linear interpolation
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.25), Color.orange.opacity(0)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // LineMark for the price line
            LineMark(
                x: .value("Time", price.time),
                y: .value("Price", price.price)
            )
            .interpolationMethod(.linear) // Retain linear interpolation
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
        .chartXScale(domain: getXAxisDomain()) // Dynamic x-axis scale based on currentTime
        //.chartOverlay { ... } // Removed to reduce rendering overhead
        //.animation(...) // Removed to reduce CPU usage
        .frame(maxWidth: .infinity, alignment: .leading) // Align Chart to leading side
        .padding([.leading, .trailing])
    }
    
    // Function to determine the x-axis domain based on the currentTime
    private func getXAxisDomain() -> ClosedRange<Date> {
        let endTime = viewModel.currentTime
        let startTime = endTime.addingTimeInterval(-10 * 60) // Last 10 minutes
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