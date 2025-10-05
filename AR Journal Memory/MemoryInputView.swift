//
//  MemoryInputView.swift
//  AR Journal Memory
//
//  UI for creating a new memory
//

import SwiftUI

struct MemoryInputView: View {
    @Binding var isPresented: Bool
    var onSave: (String, String) -> Void
    
    @State private var title: String = ""
    @State private var description: String = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, description
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("✨ Create New Memory")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Title input
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("Memory title...", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .focused($focusedField, equals: .title)
            }
            
            // Description input
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextEditor(text: $description)
                    .frame(height: 120)
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(8)
                    .autocorrectionDisabled(false)
                    .textInputAutocapitalization(.sentences)
                    .focused($focusedField, equals: .description)
            }
            
            // Buttons
            HStack(spacing: 15) {
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.6))
                        .cornerRadius(12)
                }
                
                Button(action: {
                    if !title.isEmpty {
                        onSave(title, description)
                        isPresented = false
                    }
                }) {
                    Text("Save Memory")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            Group {
                                if title.isEmpty {
                                    Color.gray.opacity(0.4)
                                } else {
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                }
                            }
                        )
                        .cornerRadius(12)
                }
                .disabled(title.isEmpty)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.85))
                .shadow(radius: 20)
        )
        .padding(.horizontal, 30)
        .onAppear {
            // Delay focus to allow keyboard system to initialize properly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusedField = .title
            }
        }
        .onDisappear {
            // Clear focus when dismissing to prevent keyboard warnings
            focusedField = nil
        }
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        MemoryInputView(isPresented: .constant(true)) { title, description in
            print("Title: \(title), Description: \(description)")
        }
    }
}
