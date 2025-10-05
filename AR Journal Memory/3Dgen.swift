//
//  ThreeDGenView.swift
//  AR Journal Memory
//
//  3D Object Generator with preset models and speech functionality
//

import SwiftUI
import RealityKit

struct ThreeDGenView: View {
    @Binding var isPresented: Bool
    var voiceNarrationEnabled: Bool
    var onPlaceObject: (String, URL) -> Void
    
    @State private var selectedModel: PresetModel? = nil
    @State private var isSpeaking = false
    @State private var speakError: String?
    
    enum PresetModel: String, CaseIterable, Identifiable {
        case couch = "Blue Couch"
        
        var id: String { rawValue }
        var fileName: String {
            switch self {
            case .couch: return "blue_couch.usdz"
            }
        }
        var icon: String {
            switch self {
            case .couch: return "sofa.fill"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🪄 Generate 3D Object")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Select a 3D model to place in AR")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            // Model Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose Model")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(PresetModel.allCases) { model in
                    Button(action: {
                        selectedModel = model
                        // Auto-narrate when model is selected
                        if voiceNarrationEnabled {
                            autoNarrate(model: model)
                        }
                    }) {
                        HStack {
                            Image(systemName: model.icon)
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 40)
                            
                            Text(model.rawValue)
                                .font(.body)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            if selectedModel == model {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(
                            selectedModel == model 
                                ? Color.blue.opacity(0.3)
                                : Color.white.opacity(0.1)
                        )
                        .cornerRadius(10)
                    }
                }
            }
            
            if let err = speakError {
                Text(err)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            
            // Action Buttons
            HStack(spacing: 15) {
                Button("Cancel") { isPresented = false }
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.6))
                    .cornerRadius(12)
                
                Button("Place in AR") {
                    if let model = selectedModel, let url = getAssetURL(for: model) {
                        onPlaceObject(model.rawValue, url)
                        isPresented = false
                    }
                }
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedModel == nil ? Color.gray.opacity(0.4) : Color.blue)
                .cornerRadius(12)
                .disabled(selectedModel == nil)
            }
            
            if isSpeaking {
                HStack(spacing: 8) {
                    ProgressView().progressViewStyle(.circular).tint(.blue)
                    Text("Speaking…")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.85))
                .shadow(radius: 20)
        )
        .padding(.horizontal, 30)
    }
    
    private func getAssetURL(for model: PresetModel) -> URL? {
        // Try workspace asset directory first
        let workspaceAsset = URL(fileURLWithPath: "/Users/fkusiapp/Desktop/dev/AR Journal Memory/asset/\(model.fileName)")
        if FileManager.default.fileExists(atPath: workspaceAsset.path) {
            return workspaceAsset
        }
        
        // Try bundle
        if let bundleURL = Bundle.main.url(forResource: model.fileName.replacingOccurrences(of: ".usdz", with: ""), withExtension: "usdz") {
            return bundleURL
        }
        
        return nil
    }
    
    private func autoNarrate(model: PresetModel) {
        Task { @MainActor in
            guard !isSpeaking else { return }
            isSpeaking = true
            speakError = nil
            do {
                let narration = try await GeminiClient.narrateTitle("A beautiful \(model.rawValue) for your AR space")
                let audio = try await ElevenLabsClient.tts(narration)
                try AudioStore.shared.play(data: audio)
            } catch {
                speakError = "Narration failed: \(error.localizedDescription)"
            }
            isSpeaking = false
        }
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        ThreeDGenView(isPresented: .constant(true), voiceNarrationEnabled: true) { name, url in
            print("Placing \(name) from \(url)")
        }
    }
}
