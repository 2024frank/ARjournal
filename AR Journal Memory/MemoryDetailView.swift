//
//  MemoryDetailView.swift
//  AR Journal Memory
//
//  UI for viewing memory details in Explore mode
//

import SwiftUI
import AVFoundation

struct MemoryDetailView: View {
    let memory: Memory
    @Binding var isPresented: Bool
    var voiceNarrationEnabled: Bool = true
    @State private var isOpening = false
    var onDelete: (() -> Void)? = nil
    
    @State private var isSpeaking = false
    @State private var speakError: String?
    @State private var hasNarrated = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { withAnimation { isPresented = false } }

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.9), Color.gray.opacity(0.6)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.black.opacity(0.3), radius: 16)
                    Image(systemName: isOpening ? "doc.text.fill" : "doc.text")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isOpening ? 360 : 0))
                        .scaleEffect(isOpening ? 1.06 : 1.0)
                }
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(memory.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                    }

                    Divider()

                    ScrollView {
                        Text(memory.description.isEmpty ? "No description added" : memory.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 4)
                    }
                    .frame(maxHeight: 220)

                    if let err = speakError {
                        Text(err)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    HStack(spacing: 12) {
                        Button(action: { withAnimation { isPresented = false } }) {
                            Text("Close")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.7)]), startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(12)
                        }

                        Button(role: .destructive, action: { onDelete?() }) {
                            Text("Delete")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                    }
                    
                    if isSpeaking {
                        HStack(spacing: 8) {
                            ProgressView().progressViewStyle(.circular).tint(.blue)
                            Text("Speaking…")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(20)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(20)
                .shadow(radius: 20)
            }
            .frame(maxWidth: 420)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { isOpening = true }
            // Auto-narrate if enabled and not already narrated
            if voiceNarrationEnabled && !hasNarrated {
                hasNarrated = true
                autoNarrate()
            }
        }
    }
    
    private func autoNarrate() {
        Task { @MainActor in
            isSpeaking = true
            speakError = nil
            do {
                let narration = try await GeminiClient.narrateTitle(memory.title)
                let audio = try await ElevenLabsClient.tts(narration)
                try AudioStore.shared.play(data: audio)
            } catch {
                speakError = "Narration failed: \(error.localizedDescription)"
            }
            isSpeaking = false
        }
    }
}

struct KeyEntryView: View {
    @Binding var geminiKey: String
    @Binding var elevenKey: String
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Gemini API Key")) {
                    SecureField("Paste key", text: $geminiKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                }
                Section(header: Text("ElevenLabs API Key")) {
                    SecureField("Paste key", text: $elevenKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("API Keys")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        MemoryDetailView(
            memory: Memory(
                title: "My First Memory",
                description: "This is a beautiful memory that I want to remember forever. It was an amazing day filled with joy and happiness.",
                position: SIMD3<Float>(0, 0, 0),
                color: .gold
            ),
            isPresented: .constant(true)
        )
    }
}
