//
//  AIClients.swift
//  AR Journal Memory
//
//  Minimal clients for Gemini narration + ElevenLabs TTS (demo-ready)
//

import Foundation
import AVFoundation
import SwiftUI

struct GeminiClient {
    static let apiKey = "AIzaSyDxPZ_1234567890_REPLACE_WITH_YOUR_KEY" // Hardcoded Gemini API key - replace with real key
    
    static func narrateTitle(_ title: String, apiKey: String? = nil) async throws -> String {
        let key = apiKey ?? GeminiClient.apiKey
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(key)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let prompt = "You are an AR narrator. Given a short note title, craft a creative one or two sentence voiceover that invites curiosity. Keep it friendly and vivid. Title: \(title)"
        let body: [String: Any] = [
            "contents": [[
                "parts": [["text": prompt]]
            ]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        // Parse minimal JSON
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let text = parts.first?["text"] as? String {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        throw URLError(.cannotParseResponse)
    }
}

struct ElevenLabsClient {
    static let defaultVoice = "21m00Tcm4TlvDq8ikWAM" // Rachel
    static let apiKey = "sk_39b2e1fcd869c882074f6dc4dc7db31efa96f4af5c90e7f8" // Hardcoded API key
    
    static func tts(_ text: String, apiKey: String? = nil, voiceId: String = defaultVoice) async throws -> Data {
        let key = apiKey ?? ElevenLabsClient.apiKey
        let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceId)?optimize_streaming_latency=0")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(key, forHTTPHeaderField: "xi-api-key")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        let payload: [String: Any] = [
            "text": text,
            "voice_settings": ["stability": 0.4, "similarity_boost": 0.7]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200, data.count > 0 else { throw URLError(.badServerResponse) }
        return data
    }
}

final class AudioStore {
    static let shared = AudioStore()
    private var player: AVAudioPlayer?
    private init() {}
    
    func play(data: Data) throws {
        player = try AVAudioPlayer(data: data)
        player?.prepareToPlay()
        player?.play()
    }
    
    func stop() { player?.stop() }
}
