// ClockView.swift
import SwiftUI

struct ClockView: View {
    @ObservedObject var viewModel: BitcoinPriceViewModel
    
    var body: some View {
        Text("Current Time: \(viewModel.currentTime, formatter: viewModel.timeFormatter)")
            .font(.caption)
            .foregroundColor(.gray)
    }
}