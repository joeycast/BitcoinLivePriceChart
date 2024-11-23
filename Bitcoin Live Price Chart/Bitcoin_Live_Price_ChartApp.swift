//
//  Bitcoin_Live_Price_ChartApp.swift
//  Bitcoin Live Price Chart
//
//  Created by Joe Castagnaro on 11/22/24.
//

import SwiftUI

@main
struct Bitcoin_Live_Price_ChartApp: App {
    @StateObject private var webSocketManager = WebSocketManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(webSocketManager)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    webSocketManager.appDidEnterBackground()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    webSocketManager.appWillEnterForeground()
                }
        }
    }
}
