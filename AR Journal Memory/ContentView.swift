//
//  ContentView.swift
//  AR Journal Memory
//
//  Created by Frank kusi Appiah on 10/4/25.
//

import SwiftUI
import RealityKit
import ARKit
import Combine
import UIKit

struct ContentView : View {
    @StateObject private var memoryManager = MemoryManager()
    @StateObject private var arCoordinator = ARCoordinatorWrapper()
    @StateObject private var locationManager = LocationManager()
    @State private var hasStarted = false
    @State private var isBooting = false
    @State private var countdown = 7
    @AppStorage("voiceNarrationEnabled") private var voiceNarrationEnabled = true

    var body: some View {
        ZStack {
            if !hasStarted {
                WelcomeView(
                    isBooting: isBooting,
                    countdown: countdown,
                    onStart: {
                        guard !isBooting else { return }
                        isBooting = true
                        countdown = 7
                        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                            if countdown > 1 {
                                countdown -= 1
                            } else {
                                timer.invalidate()
                                isBooting = false
                                hasStarted = true
                            }
                        }
                    }
                )
                .ignoresSafeArea()
            }
            if hasStarted {
                ZStack {
                    TabView {
                        // Add Memory tab
                        ZStack {
                            SharedARView(
                                memoryManager: memoryManager,
                                arCoordinator: arCoordinator,
                                locationManager: locationManager,
                                currentMode: .add
                            )
                            .edgesIgnoringSafeArea(.all)
                            
                            AddMemoryOverlay(
                                memoryManager: memoryManager,
                                arCoordinator: arCoordinator,
                                locationManager: locationManager,
                                voiceNarrationEnabled: voiceNarrationEnabled
                            )
                        }
                        .tabItem { Label("Add Memory", systemImage: "plus.app") }
                        
                        // Generate 3D Object tab
                        ZStack {
                            SharedARView(
                                memoryManager: memoryManager,
                                arCoordinator: arCoordinator,
                                locationManager: locationManager,
                                currentMode: .add
                            )
                            .edgesIgnoringSafeArea(.all)
                            
                            Generate3DOverlay(arCoordinator: arCoordinator, voiceNarrationEnabled: voiceNarrationEnabled)
                        }
                        .tabItem { Label("Generate 3D", systemImage: "cube") }
                    }
                    
                    // Voice Narration Toggle - Top Right
                    VStack {
                        HStack {
                            Spacer()
                            Toggle(isOn: $voiceNarrationEnabled) {
                                HStack(spacing: 6) {
                                    Image(systemName: voiceNarrationEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                                        .foregroundColor(.white)
                                    Text("Voice")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(20)
                            .padding(.top, 50)
                            .padding(.trailing, 16)
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}

// Wrapper to hold AR coordinator
class ARCoordinatorWrapper: ObservableObject {
    var coordinator: ARViewContainer.Coordinator?
    @Published var pendingPosition: SIMD3<Float>?
    @Published var selectedMemory: Memory?
    @Published var isRelocalizing: Bool = false
}

// Shared AR View - Single instance
struct SharedARView: UIViewRepresentable {
    @ObservedObject var memoryManager: MemoryManager
    @ObservedObject var arCoordinator: ARCoordinatorWrapper
    @ObservedObject var locationManager: LocationManager
    var currentMode: ARViewMode
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .none
        config.frameSemantics = .smoothedSceneDepth
        arView.session.run(config, options: [])
        arView.session.delegate = context.coordinator
        
        context.coordinator.arView = arView
        context.coordinator.mode = currentMode
        context.coordinator.memoryManager = memoryManager
        context.coordinator.locationManager = locationManager
        context.coordinator.arCoordinatorWrapper = arCoordinator
        arCoordinator.coordinator = context.coordinator
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(ARViewContainer.Coordinator.handleTap))
        arView.addGestureRecognizer(tapGesture)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            context.coordinator.loadMemoriesIntoScene()
        }
        
        print("✅ Shared AR View created")
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) { }
    
    static func dismantleUIView(_ uiView: ARView, coordinator: ARViewContainer.Coordinator) {
        coordinator.cancellable?.cancel()
        coordinator.cancellable = nil
        uiView.session.pause()
    }
    
    func makeCoordinator() -> ARViewContainer.Coordinator { ARViewContainer.Coordinator() }
}

// Add Memory Overlay (also shows detail when a memory is selected)
struct AddMemoryOverlay: View {
    @ObservedObject var memoryManager: MemoryManager
    @ObservedObject var arCoordinator: ARCoordinatorWrapper
    @ObservedObject var locationManager: LocationManager
    var voiceNarrationEnabled: Bool
    @State private var showingMemoryInput = false
    
    var body: some View {
        ZStack {
            if showingMemoryInput {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showingMemoryInput = false
                        arCoordinator.pendingPosition = nil
                    }
                MemoryInputView(
                    isPresented: $showingMemoryInput,
                    onSave: { title, description in
                        if let position = arCoordinator.pendingPosition {
                            let memory = Memory(
                                title: title,
                                description: description,
                                position: position,
                                color: .random(),
                                location: nil,
                                worldMapData: nil
                            )
                            memoryManager.addMemory(memory)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                arCoordinator.coordinator?.loadMemoriesIntoScene()
                            }
                        }
                        arCoordinator.pendingPosition = nil
                    }
                )
            }
            
            if let memory = arCoordinator.selectedMemory {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { arCoordinator.selectedMemory = nil }
                MemoryDetailView(
                    memory: memory,
                    isPresented: Binding(
                        get: { arCoordinator.selectedMemory != nil },
                        set: { if !$0 { arCoordinator.selectedMemory = nil } }
                    ),
                    voiceNarrationEnabled: voiceNarrationEnabled,
                    onDelete: {
                        memoryManager.deleteMemory(id: memory.id)
                        arCoordinator.selectedMemory = nil
                        arCoordinator.coordinator?.loadMemoriesIntoScene()
                    }
                )
            }
        }
        .onChange(of: arCoordinator.pendingPosition) { newValue in
            if newValue != nil { showingMemoryInput = true }
        }
    }
}

// Generate 3D overlay that presents the 3D object generator UI
struct Generate3DOverlay: View {
    @ObservedObject var arCoordinator: ARCoordinatorWrapper
    var voiceNarrationEnabled: Bool
    @State private var showingGenerator: Bool = true
    @State private var showingPlacementHint: Bool = false
    
    var body: some View {
        ZStack {
            if showingGenerator {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { showingGenerator = false }
                ThreeDGenView(
                    isPresented: $showingGenerator,
                    voiceNarrationEnabled: voiceNarrationEnabled,
                    onPlaceObject: { name, url in
                        showingGenerator = false
                        arCoordinator.coordinator?.load3DModel(from: url, name: name)
                        showingPlacementHint = true
                        // Auto-hide hint after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showingPlacementHint = false
                        }
                    }
                )
            }
            
            // Placement hint
            if showingPlacementHint {
                VStack {
                    Spacer()
                    Text("👆 Tap a surface to place your 3D object")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                        .padding(.bottom, 40)
                }
            }
        }
    }
}

enum ARViewMode { case add, explore }

// ARViewContainer namespace for Coordinator
enum ARViewContainer {
    
    class Coordinator: NSObject, ARSessionDelegate {
        var arView: ARView?
        var mode: ARViewMode = .add
        var memoryManager: MemoryManager?
        var locationManager: LocationManager?
        var memoryEntities: [UUID: AnchorEntity] = [:]
        var textEntities: [UUID: Entity] = [:]
        var cancellable: Cancellable?
        weak var arCoordinatorWrapper: ARCoordinatorWrapper?
        var pending3DModel: (url: URL, name: String)?
        var placed3DModels: [AnchorEntity] = []
        
        func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) { }
        
        @objc func handleTap(recognizer: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let tapLocation = recognizer.location(in: arView)
            
            // If there's a pending 3D model, place it
            if let model = pending3DModel {
                let results = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
                if let first = results.first {
                    place3DModel(from: model.url, at: first.worldTransform, name: model.name)
                    pending3DModel = nil
                    return
                }
            }
            
            // If a memory entity was tapped → open it; else create at surface
            if let entity = arView.entity(at: tapLocation), let memory = findMemory(from: entity) {
                openTreasureAnimation(for: memory, on: arView)
                DispatchQueue.main.async { [weak self] in
                    self?.arCoordinatorWrapper?.selectedMemory = memory
                }
                return
            }
            
            let results = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
            if let first = results.first {
                let p = first.worldTransform.columns.3
                DispatchQueue.main.async { [weak self] in
                    self?.arCoordinatorWrapper?.pendingPosition = SIMD3<Float>(p.x, p.y, p.z)
                }
            } else if let pos = getPositionInFrontOfCamera() {
                DispatchQueue.main.async { [weak self] in
                    self?.arCoordinatorWrapper?.pendingPosition = pos
                }
            }
        }
        
        private func findMemory(from entity: Entity) -> Memory? {
            var current: Entity? = entity
            var id: UUID?
            while let e = current {
                if let uuid = UUID(uuidString: e.name.split(separator: "_").last.map(String.init) ?? "") { id = uuid; break }
                current = e.parent
            }
            guard let mid = id else { return nil }
            return memoryManager?.memories.first(where: { $0.id == mid })
        }
        
        func loadMemoriesIntoScene() {
            guard let arView = arView, let memoryManager = memoryManager else { return }
            cancellable?.cancel(); cancellable = nil
            for (_, anchor) in memoryEntities { arView.scene.removeAnchor(anchor) }
            memoryEntities.removeAll(); textEntities.removeAll()
            for mem in memoryManager.memories { createTreasureBox(for: mem, in: arView) }
            if !textEntities.isEmpty { startTextRotationUpdates() }
        }
        
        // Treasure box model
        func createTreasureBox(for memory: Memory, in arView: ARView) {
            let container = Entity(); container.name = "container_\(memory.id.uuidString)"
            let baseSize: SIMD3<Float> = [0.14, 0.08, 0.14]
            // Base
            let baseMaterial = UnlitMaterial(color: memory.color.uiColor)
            let base = ModelEntity(mesh: MeshResource.generateBox(size: baseSize, cornerRadius: 0.01), materials: [baseMaterial])
            base.name = "treasureBase_\(memory.id.uuidString)"
            // Lid
            let lidSize: SIMD3<Float> = [baseSize.x * 1.02, baseSize.y * 0.25, baseSize.z * 1.02]
            let lidMaterial = UnlitMaterial(color: memory.color.uiColor.withAlphaComponent(0.95))
            let lid = ModelEntity(mesh: MeshResource.generateBox(size: lidSize, cornerRadius: 0.008), materials: [lidMaterial])
            lid.name = "treasureLid_\(memory.id.uuidString)"
            let hinge = Entity(); hinge.name = "treasureHinge_\(memory.id.uuidString)"
            hinge.position = [0, baseSize.y * 0.5 + lidSize.y * 0.5, -baseSize.z * 0.5]
            lid.position = [0, 0, lidSize.z * 0.5]; hinge.addChild(lid)
            // Latch
            let latchMaterial = UnlitMaterial(color: UIColor.systemYellow)
            let latch = ModelEntity(mesh: MeshResource.generateBox(size: [baseSize.x * 0.22, baseSize.y * 0.1, baseSize.z * 0.06]), materials: [latchMaterial])
            latch.position = [0, 0, baseSize.z * 0.52]
            container.addChild(base); container.addChild(hinge); container.addChild(latch)
            // Title above box
            let titleMesh = MeshResource.generateText(memory.title, extrusionDepth: 0.003, font: .systemFont(ofSize: 0.04, weight: .semibold), containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail)
            let titleEntity = ModelEntity(mesh: titleMesh, materials: [UnlitMaterial(color: .white)])
            let tb = titleEntity.visualBounds(relativeTo: titleEntity); let tw = tb.max.x - tb.min.x
            titleEntity.position = [-tw/2, baseSize.y * 0.9, 0]; titleEntity.name = "title_\(memory.id.uuidString)"
            textEntities[memory.id] = titleEntity; container.addChild(titleEntity)
            // Collisions
            base.generateCollisionShapes(recursive: true); lid.generateCollisionShapes(recursive: true); latch.generateCollisionShapes(recursive: true)
            let anchor = AnchorEntity(world: memory.simdPosition); anchor.addChild(container); arView.scene.addAnchor(anchor); memoryEntities[memory.id] = anchor
        }
        
        private func openTreasureAnimation(for memory: Memory, on arView: ARView) {
            guard let anchor = memoryEntities[memory.id], let hinge = anchor.findEntity(named: "treasureHinge_\(memory.id.uuidString)") else { return }
            let parent = hinge.parent; var target = hinge.transform
            let rot = simd_quatf(angle: -.pi/2.8, axis: [1, 0, 0])
            target.rotation = simd_normalize(rot * hinge.transform.rotation)
            hinge.move(to: target, relativeTo: parent, duration: 0.4, timingFunction: .easeInOut)
        }
        
        private func startTextRotationUpdates() {
            guard let arView = arView else { return }
            cancellable?.cancel()
            cancellable = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
                guard let self = self, let arView = self.arView, let camT = arView.session.currentFrame?.camera.transform else { return }
                let cam = camT.columns.3
                for (_, title) in self.textEntities {
                    let pos = title.position(relativeTo: nil)
                    var toCam = SIMD3<Float>(cam.x - pos.x, cam.y - pos.y, cam.z - pos.z)
                    let len = simd_length(toCam); if len < 0.005 { continue }
                    toCam /= len
                    let q = simd_quatf(from: SIMD3<Float>(0,0,-1), to: toCam)
                    title.orientation = simd_normalize(q)
                }
            }
        }
        
        private func getPositionInFrontOfCamera(distance: Float = 0.5) -> SIMD3<Float>? {
            guard let arView = arView, let camT = arView.session.currentFrame?.camera.transform else { return nil }
            var t = matrix_identity_float4x4; t.columns.3.z = -distance
            let ft = simd_mul(camT, t); let p = ft.columns.3
            return SIMD3<Float>(p.x, p.y, p.z)
        }
        
        // Load a 3D model and prepare it for placement
        func load3DModel(from url: URL, name: String) {
            pending3DModel = (url: url, name: name)
            print("✅ Loaded 3D model: \(name)")
        }
        
        // Place a 3D model in the AR scene
        private func place3DModel(from url: URL, at transform: simd_float4x4, name: String) {
            guard let arView = arView else { return }
            
            do {
                // Load the USDZ model
                let entity = try ModelEntity.load(contentsOf: url)
                
                // Scale the model appropriately (adjust as needed)
                entity.scale = [0.3, 0.3, 0.3]
                
                // Create anchor at the tap location
                let anchor = AnchorEntity(world: transform)
                anchor.addChild(entity)
                
                // Add to scene
                arView.scene.addAnchor(anchor)
                placed3DModels.append(anchor)
                
                print("✅ Placed 3D model '\(name)' in AR scene")
            } catch {
                print("❌ Failed to load 3D model: \(error.localizedDescription)")
            }
        }
    }
}

#Preview { ContentView() }
