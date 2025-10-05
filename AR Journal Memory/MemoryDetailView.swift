//
//  MemoryDetailView.swift
//  AR Journal Memory
//
//  UI for viewing memory details in Explore mode
//

import SwiftUI

struct MemoryDetailView: View {
    let memory: Memory
    @Binding var isPresented: Bool
    @State private var isOpening = false
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            // Dim background for professional modal look
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { withAnimation { isPresented = false } }

            VStack(spacing: 0) {
                // Top back button (gray theme)
                HStack {
                    Button(action: { withAnimation { isPresented = false } }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.gray.opacity(0.85))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Treasure box opening animation
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(0.9),
                                    Color.gray.opacity(0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.black.opacity(0.3), radius: 20)
                    
                    Image(systemName: isOpening ? "gift.fill" : "shippingbox.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isOpening ? 360 : 0))
                        .scaleEffect(isOpening ? 1.2 : 1.0)
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                // Memory content card
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    HStack {
                        Text(memory.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Color indicator
                        Circle()
                            .fill(Color(memory.color.uiColor))
                            .frame(width: 30, height: 30)
                            .shadow(radius: 3)
                    }
                    
                    Divider()
                    
                    // Description
                    ScrollView {
                        Text(memory.description.isEmpty ? "No description added" : memory.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 200)
                    
                    // Date created
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                        Text(memory.dateCreated, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            withAnimation {
                                isPresented = false
                            }
                        }) {
                            Text("Close")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.gray,
                                            Color.gray.opacity(0.7)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        
                        Button(role: .destructive, action: {
                            onDelete?()
                        }) {
                            Text("Delete")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(24)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(20)
                .shadow(radius: 20)
            }
            .padding(.horizontal, 30)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isOpening = true
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
