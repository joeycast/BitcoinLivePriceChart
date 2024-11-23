//
//  WebsocketManager.swift
//  Bitcoin Live Price Chart
//
//  Created by Joe Castagnaro on 11/22/24.
//

import Foundation
import Combine

class WebSocketManager: ObservableObject {
    @Published var latestPrice: Double?
    private var webSocketTask: URLSessionWebSocketTask?
    private var cancellables = Set<AnyCancellable>()
    
    private let url = URL(string: "wss://ws-feed.exchange.coinbase.com")!
    
    init() {
        connect()
    }
    
    deinit {
        disconnect()
    }
    
    func connect() {
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        subscribe()
        receiveMessages()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
    
    private func subscribe() {
        let subscribeMessage: [String: Any] = [
            "type": "subscribe",
            "product_ids": ["BTC-USD"],
            "channels": ["level2", "heartbeat", [
                "name": "ticker",
                "product_ids": ["BTC-USD"]
            ]]
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: subscribeMessage, options: []),
           let jsonString = String(data: data, encoding: .utf8) {
            let message = URLSessionWebSocketTask.Message.string(jsonString)
            webSocketTask?.send(message) { error in
                if let error = error {
                    print("WebSocket subscription error: \(error)")
                } else {
                    print("Subscribed to BTC-USD ticker.")
                }
            }
        }
    }
    
    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("WebSocket receiving error: \(error)")
                self?.reconnect()
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleMessage(text)
                    }
                @unknown default:
                    print("Unknown message format received.")
                }
                self?.receiveMessages()
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let type = json["type"] as? String,
           type == "ticker",
           let priceStr = json["price"] as? String,
           let price = Double(priceStr) {
            DispatchQueue.main.async {
                self.latestPrice = price
            }
        }
    }
    
    private func reconnect() {
        disconnect()
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.connect()
        }
    }
}

extension WebSocketManager {
    func appDidEnterBackground() {
        disconnect()
    }
    
    func appWillEnterForeground() {
        connect()
    }
}
