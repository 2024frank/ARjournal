//
//  WelcomeView.swift
//  AR Journal Memory
//
//  Intro screen that requests permissions and starts the AR experience
//

import SwiftUI

struct WelcomeView: View {
    var isBooting: Bool = false
    var countdown: Int = 5
    var onStart: () -> Void
    
    init(isBooting: Bool = false, countdown: Int = 5, onStart: @escaping () -> Void) {
        self.isBooting = isBooting
        self.countdown = countdown
        self.onStart = onStart
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.95), Color.gray.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                    Text("AR Journal Memory")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Let's put notes in the real world virtually and never lose them.")
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                
                // Catchy one-liner
                Text("Place living notes in your space and open them when it matters.")
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(14)
                
                // 3D-like loading animation during boot
                if isBooting {
                    LoadingChest(countdown: countdown)
                        .padding(.top, 10)
                }
                
                Spacer()
                
                VStack(spacing: 10) {
                    Button(action: onStart) {
                        Text(isBooting ? "Starting..." : "Start")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray)
                            .cornerRadius(14)
                            .shadow(radius: 10)
                            .padding(.horizontal, 24)
                    }
                    .disabled(isBooting)
                    
                    if isBooting {
                        Text("Preparing AR... \(countdown)s")
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.bottom, 60)
            }
            .padding()
        }
    }
}

private struct LoadingChest: View {
    @State private var rotate = false
    var countdown: Int
    
    var body: some View {
        ZStack {
            // Simple 3D-ish envelope shape
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.2))
                .frame(width: 140, height: 90)
                .rotation3DEffect(.degrees(rotate ? 360 : 0), axis: (x: 0.3, y: 1, z: 0.1))
                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
            
            // Flap impression
            Triangle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 120, height: 50)
                .offset(y: -10)
                .rotation3DEffect(.degrees(rotate ? 360 : 0), axis: (x: 0.3, y: 1, z: 0.1))
            
            Text("\(countdown)")
                .font(.title2).bold()
                .foregroundColor(.white)
                .shadow(radius: 5)
        }
        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: rotate)
        .onAppear { rotate = true }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    WelcomeView(isBooting: true, countdown: 6, onStart: {})
}


