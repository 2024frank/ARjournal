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
    var onPlaceObject: (String, URL) -> Void
    
    @State private var selectedModel: PresetModel? = nil
    
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
        // Try bundle first (this is where it will be in the app)
        let resourceName = model.fileName.replacingOccurrences(of: ".usdz", with: "")
        if let bundleURL = Bundle.main.url(forResource: resourceName, withExtension: "usdz") {
            print("✅ Found asset in bundle: \(bundleURL)")
            return bundleURL
        }
        
        // Fallback: Try workspace asset directory for development
        let workspaceAsset = URL(fileURLWithPath: "/Users/fkusiapp/Desktop/dev/AR Journal Memory/asset/\(model.fileName)")
        if FileManager.default.fileExists(atPath: workspaceAsset.path) {
            print("✅ Found asset in workspace: \(workspaceAsset)")
            return workspaceAsset
        }
        
        print("❌ Asset not found: \(model.fileName)")
        return nil
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        ThreeDGenView(isPresented: .constant(true)) { name, url in
            print("Placing \(name) from \(url)")
        }
    }
}
