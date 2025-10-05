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
    @State private var selectedTab = 0
    @State private var hasStarted = false
    @State private var isBooting = false
    @State private var countdown = 7

    var body: some View {
        ZStack {
            // Welcome overlay (gates AR initialization)
            if !hasStarted {
                WelcomeView(
                    isBooting: isBooting,
                    countdown: countdown,
                    onStart: {
                        guard !isBooting else { return }
                        isBooting = true
                        locationManager.requestPermission()
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
            // Single shared AR view
            if hasStarted {
                SharedARView(
                    memoryManager: memoryManager,
                    arCoordinator: arCoordinator,
                    locationManager: locationManager,
                    currentMode: selectedTab == 0 ? .add : .explore
                )
                .edgesIgnoringSafeArea(.all)
            }
            
            // Relocalization overlay
            if arCoordinator.isRelocalizing {
                VStack {
                    HStack {
                        Image(systemName: "arkit")
                            .foregroundColor(.white)
                        Text("Move your device to relocalize the scene…")
                            .foregroundColor(.white)
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.black.opacity(0.6)))
                    .padding(.top, 50)
                    Spacer()
                }
            }
            
            // Tab-specific UI overlays
            if hasStarted {
                if selectedTab == 0 {
                    AddMemoryOverlay(memoryManager: memoryManager, arCoordinator: arCoordinator, locationManager: locationManager)
                } else {
                    ExploreMemoryOverlay(memoryManager: memoryManager, arCoordinator: arCoordinator)
                }
            }
            
            // Tab selector at bottom - Fixed position (hidden until Start)
            if hasStarted {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 40) {
                        TabButton(
                            icon: "plus.square.fill",
                            label: "Add Memory",
                            isSelected: selectedTab == 0
                        ) {
                            selectedTab = 0
                        }
                        
                        TabButton(
                            icon: "map.fill",
                            label: "Explore",
                            isSelected: selectedTab == 1
                        ) {
                            selectedTab = 1
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.85))
                            .shadow(radius: 10)
                    )
                    .padding(.bottom, 30)
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .onAppear {
            // Defer requesting permission until user taps Start
        }
    }
}

// Custom tab button
struct TabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : Color.white.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(isSelected ? 0.18 : 0.0))
            )
            .overlay(
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 2)
                    .opacity(isSelected ? 1 : 0)
                , alignment: .bottom
            )
            .frame(minWidth: 100)
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
        
        // Configure AR session with optimized settings
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .none // Reduce resource usage
        config.frameSemantics = .smoothedSceneDepth
        
        // Run session with reset options
        arView.session.run(config, options: [])
        arView.session.delegate = context.coordinator
        
        // Setup coordinator
        context.coordinator.arView = arView
        context.coordinator.mode = currentMode
        context.coordinator.memoryManager = memoryManager
        context.coordinator.locationManager = locationManager
        context.coordinator.arCoordinatorWrapper = arCoordinator
        arCoordinator.coordinator = context.coordinator
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(ARViewContainer.Coordinator.handleTap))
        arView.addGestureRecognizer(tapGesture)
        
        // Load memories initially
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            context.coordinator.loadMemoriesIntoScene()
            context.coordinator.attemptRelocalizationIfPossible()
        }
        
        print("✅ Shared AR View created")
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Update mode when tab changes (don't reload scene)
        if context.coordinator.mode != currentMode {
            context.coordinator.mode = currentMode
            print("🔄 Switched to \(currentMode == .add ? "ADD" : "EXPLORE") mode")
            if currentMode == .explore {
                // Defer to next runloop to avoid publishing changes during updates
                DispatchQueue.main.async {
                    context.coordinator.attemptRelocalizationIfPossible()
                }
            }
        }
        // Ensure collision shapes are present for hit-testing in Explore
        context.coordinator.ensureCollisionShapesForAll()
    }
    
    static func dismantleUIView(_ uiView: ARView, coordinator: ARViewContainer.Coordinator) {
        // Clean up when view is destroyed
        coordinator.cancellable?.cancel()
        coordinator.cancellable = nil
        uiView.session.pause()
        print("🛑 AR View cleaned up")
    }
    
    func makeCoordinator() -> ARViewContainer.Coordinator {
        return ARViewContainer.Coordinator()
    }
}

// Add Memory Overlay
struct AddMemoryOverlay: View {
    @ObservedObject var memoryManager: MemoryManager
    @ObservedObject var arCoordinator: ARCoordinatorWrapper
    @ObservedObject var locationManager: LocationManager
    @State private var showingMemoryInput = false

    var body: some View {
        ZStack {
            // Instruction overlay
            if !showingMemoryInput {
                VStack {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(.white)
                        Text("Tap anywhere to add a memory")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.6))
                            .shadow(radius: 10)
                    )
                    .padding(.top, 50)
                    
                    Spacer()
                }
            }
            
            // Memory input sheet
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
                            // Save ARWorldMap with the memory
                            arCoordinator.coordinator?.saveCurrentWorldMap { worldMapData in
                                let memory = Memory(
                                    title: title,
                                    description: description,
                                    position: position,
                                    color: .random(),
                                    location: locationManager.currentLocation,
                                    worldMapData: worldMapData
                                )
                                memoryManager.addMemory(memory)
                                
                                print("💾 Memory saved with location: \(locationManager.currentLocation?.latitude ?? 0), \(locationManager.currentLocation?.longitude ?? 0)")
                                
                                // Reload scene with new memory
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    arCoordinator.coordinator?.reloadSceneIfNeeded()
                                }
                            }
                        }
                        arCoordinator.pendingPosition = nil
                    }
                )
            }
        }
        .onChange(of: arCoordinator.pendingPosition) { newValue in
            if newValue != nil {
                showingMemoryInput = true
            }
        }
    }
}

// Explore Memory Overlay
struct ExploreMemoryOverlay: View {
    @ObservedObject var memoryManager: MemoryManager
    @ObservedObject var arCoordinator: ARCoordinatorWrapper
    
    var body: some View {
        ZStack {
            // Instruction overlay
            if arCoordinator.selectedMemory == nil {
                VStack {
                    HStack {
                        Image(systemName: "gift.fill")
                            .foregroundColor(.white)
                        Text("Tap a treasure box to open it")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.6))
                            .shadow(radius: 10)
                    )
                    .padding(.top, 50)
                    
                    Spacer()
                    
                    // Memory count
                    if memoryManager.memories.isEmpty {
                        Text("No memories yet\nGo to Add Memory tab to create one!")
                            .multilineTextAlignment(.center)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.7))
                            )
                    }
                    
                    Spacer()
                        .frame(height: 100)
                }
            }
            
            // Memory detail view
            if let memory = arCoordinator.selectedMemory {
                Color.black.opacity(0.4)
        .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        arCoordinator.selectedMemory = nil
                    }
                
                MemoryDetailView(
                    memory: memory,
                    isPresented: Binding(
                        get: { arCoordinator.selectedMemory != nil },
                        set: { if !$0 { arCoordinator.selectedMemory = nil } }
                    ),
                    onDelete: {
                        // Confirm then delete
                        memoryManager.deleteMemory(id: memory.id)
                        arCoordinator.selectedMemory = nil
                        arCoordinator.coordinator?.reloadSceneIfNeeded()
                    }
                )
                // Swipe right to go back
                .gesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                        .onEnded { value in
                            if value.translation.width > 60 { arCoordinator.selectedMemory = nil }
                        }
                )
            }
        }
    }
}

enum ARViewMode {
    case add      // Can create new memories
    case explore  // Can open existing memories
}

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
        
        // Distance threshold in meters - only show memories within this range
        let proximityThreshold: Double = 50.0 // 50 meters
        
        func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
            switch camera.trackingState {
            case .normal:
                arCoordinatorWrapper?.isRelocalizing = false
            default:
                break
            }
        }

        @objc func handleTap(recognizer: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            
            let tapLocation = recognizer.location(in: arView)
            
            if mode == .add {
                // ADD MODE: Create new memory at tap location
                print("🎯 Tap detected in ADD mode")
                
                // Perform raycast to find a surface
                let results = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
                
                if let firstResult = results.first {
                    let position = firstResult.worldTransform.columns.3
                    let simdPosition = SIMD3<Float>(position.x, position.y, position.z)
                    
                    // Notify through coordinator wrapper
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self, let wrapper = self.arCoordinatorWrapper else { return }
                        wrapper.pendingPosition = simdPosition
                    }
                } else {
                    // Place in front of camera if no surface detected
                    if let position = getPositionInFrontOfCamera() {
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self, let wrapper = self.arCoordinatorWrapper else { return }
                            wrapper.pendingPosition = position
                        }
                    }
                }
            } else {
                // EXPLORE MODE: Check if tapping on a memory box
                print("🎯 Tap detected in EXPLORE mode")
                
                // Cast ray from tap location to check for entity hits
                if let entity = arView.entity(at: tapLocation) {
                    if let memory = findMemory(from: entity) {
                        // Animate sheet emphasis
                        openEnvelopeAnimation(for: memory, on: arView)
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self, let wrapper = self.arCoordinatorWrapper else { return }
                            wrapper.selectedMemory = memory
                        }
                    }
                }
            }
        }
        
        private func findMemory(from entity: Entity) -> Memory? {
            // Walk up the hierarchy to find a name containing a UUID
            var current: Entity? = entity
            var foundUUID: UUID?
            while let e = current {
                if let uuid = extractUUID(fromName: e.name) { foundUUID = uuid; break }
                current = e.parent
            }
            guard let id = foundUUID,
                  let memory = memoryManager?.memories.first(where: { $0.id == id }) else { return nil }
            return memory
        }
        
        private func extractUUID(fromName name: String) -> UUID? {
            // Names are like "treasureBox_UUID" or "lid_UUID" or "title_UUID" or "container_UUID"
            let parts = name.split(separator: "_")
            guard let last = parts.last else { return nil }
            return UUID(uuidString: String(last))
        }
        
        func loadMemoriesIntoScene() {
            guard let arView = arView, let memoryManager = memoryManager else { return }
            
            // Filter memories by proximity to current location
            let nearbyMemories = filterNearbyMemories(memoryManager.memories)
            
            // Don't reload if already loaded with same count
            if memoryEntities.count == nearbyMemories.count && !nearbyMemories.isEmpty {
                return
            }
            
            // Cancel any existing subscription first
            cancellable?.cancel()
            cancellable = nil
            
            // Remove old entities
            for (_, anchor) in memoryEntities {
                arView.scene.removeAnchor(anchor)
            }
            memoryEntities.removeAll()
            textEntities.removeAll()
            
            // Add nearby memories to the scene
            for memory in nearbyMemories {
                createEnvelope(for: memory, in: arView)
            }
            
            // Start updating text rotations to face camera (only if we have text entities)
            if !textEntities.isEmpty {
                startTextRotationUpdates()
            }
            
            let filteredCount = memoryManager.memories.count - nearbyMemories.count
            print("📦 Loaded \(nearbyMemories.count) nearby treasure boxes into scene (filtered out \(filteredCount) distant memories)")
        }
        
        func filterNearbyMemories(_ memories: [Memory]) -> [Memory] {
            guard let currentLocation = locationManager?.currentLocation else {
                // No location available - show all memories (for testing without GPS)
                print("⚠️ No GPS location - showing all memories")
                return memories
            }
            
            return memories.filter { memory in
                guard let memoryLocation = memory.clLocation else {
                    // Memory has no location - include it for backward compatibility
                    return true
                }
                
                let distance = locationManager?.distance(from: currentLocation, to: memoryLocation) ?? Double.infinity
                let isNearby = distance <= proximityThreshold
                
                if !isNearby {
                    print("🚫 Filtered out '\(memory.title)' - \(Int(distance))m away")
                }
                
                return isNearby
            }
        }
        
        func reloadSceneIfNeeded() {
            guard let memoryManager = memoryManager else { return }
            
            // Only reload if memory count changed
            let nearbyMemories = filterNearbyMemories(memoryManager.memories)
            if memoryEntities.count != nearbyMemories.count {
                loadMemoriesIntoScene()
            }
        }
        
        func saveCurrentWorldMap(completion: @escaping (Data?) -> Void) {
            guard let arView = arView else {
                completion(nil)
                return
            }
            
            arView.session.getCurrentWorldMap { worldMap, error in
                if let error = error as NSError? {
                    if error.domain == ARError.errorDomain, error.code == ARError.insufficientFeatures.rawValue {
                        // Not enough features yet; return without logging as an error
                        completion(nil)
                        return
                    }
                    print("❌ Failed to get world map: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let map = worldMap else {
                    completion(nil)
                    return
                }
                
                do {
                    let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                    print("✅ ARWorldMap saved (\(data.count) bytes)")
                    completion(data)
                } catch {
                    print("❌ Failed to archive world map: \(error.localizedDescription)")
                    completion(nil)
                }
            }
        }
        
        func startTextRotationUpdates() {
            guard let arView = arView else { return }
            
            // Cancel previous subscription
            cancellable?.cancel()
            
            // Subscribe to scene updates to rotate text towards camera
            cancellable = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
                guard let self = self,
                      let arView = self.arView,
                      let cameraTransform = arView.session.currentFrame?.camera.transform else { return }
                
                let cameraPosition = cameraTransform.columns.3
                
                // Update each text entity to face camera (Y-axis rotation only)
                for (_, textContainer) in self.textEntities {
                    // Ensure entity is still valid and attached to the scene
                    guard textContainer.isEnabled, textContainer.isActive else { continue }
                    
                    // Get world position of text container
                    let textPosition = textContainer.position(relativeTo: nil)
                    
                    // Calculate direction to camera (only X and Z, ignore Y for upright text)
                    let dx = cameraPosition.x - textPosition.x
                    let dz = cameraPosition.z - textPosition.z
                    
                    // Skip if camera is too close (within 5cm) to avoid erratic rotation
                    let distanceSquared = dx * dx + dz * dz
                    guard distanceSquared > 0.0025 else { continue } // 5cm threshold
                    
                    // Calculate Y-axis rotation angle
                    let angle = atan2(dx, dz)
                    
                    // Apply rotation only on Y axis (keeps text upright)
                    textContainer.orientation = simd_quatf(angle: angle, axis: [0, 1, 0])
                    
                    // Subtle bobbing motion
                    let t = Float(CACurrentMediaTime())
                    let bob: Float = 0.005 * sinf(t * 2.0)
                    var trans = textContainer.transform
                    trans.translation.y += bob
                    textContainer.transform = trans
                }
            }
        }
        
        /// Ensure all placed memory entities have collision shapes (needed for taps in Explore)
        func ensureCollisionShapesForAll() {
            for (_, anchor) in memoryEntities {
                generateCollisionRecursively(anchor)
            }
        }
        
        private func generateCollisionRecursively(_ entity: Entity) {
            if let model = entity as? ModelEntity {
                model.generateCollisionShapes(recursive: false)
            }
            for child in entity.children {
                generateCollisionRecursively(child)
            }
        }
        
        func createEnvelope(for memory: Memory, in arView: ARView) {
            // Sheet container
            let containerEntity = Entity()
            containerEntity.name = "sheetContainer_\(memory.id.uuidString)"
            
            // Sheet body: thin upright box (smaller)
            let sheetSize: SIMD3<Float> = [0.16, 0.20, 0.004]
            let sheetMesh = MeshResource.generateBox(size: sheetSize, cornerRadius: 0.008)
            var sheetMaterial = SimpleMaterial()
            sheetMaterial.color = .init(tint: UIColor(white: 0.98, alpha: 1.0), texture: nil)
            sheetMaterial.roughness = .init(floatLiteral: 0.35)
            sheetMaterial.metallic = .init(floatLiteral: 0.0)
            let sheetEntity = ModelEntity(mesh: sheetMesh, materials: [sheetMaterial])
            sheetEntity.name = "sheet_\(memory.id.uuidString)"
            
            // Subtle border
            let borderMesh = MeshResource.generateBox(size: [sheetSize.x * 0.98, sheetSize.y * 0.98, sheetSize.z * 1.02], cornerRadius: 0.006)
            var borderMaterial = SimpleMaterial()
            borderMaterial.color = .init(tint: UIColor(white: 0.95, alpha: 1.0), texture: nil)
            borderMaterial.roughness = .init(floatLiteral: 0.5)
            let borderEntity = ModelEntity(mesh: borderMesh, materials: [borderMaterial])
            borderEntity.position = [0, 0, sheetSize.z * 0.01]
            
            containerEntity.addChild(sheetEntity)
            containerEntity.addChild(borderEntity)
            
            // Centered title (use the same font size/style as the previous body preview)
            let centeredTitleMesh = MeshResource.generateText(
                memory.title,
                extrusionDepth: 0.001,
                font: .systemFont(ofSize: 0.02, weight: .regular),
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byTruncatingTail
            )
            let centeredTitleMat = UnlitMaterial(color: UIColor.darkGray)
            let centeredTitleEntity = ModelEntity(mesh: centeredTitleMesh, materials: [centeredTitleMat])
            let ctb = centeredTitleEntity.visualBounds(relativeTo: centeredTitleEntity)
            let ctw = ctb.max.x - ctb.min.x
            centeredTitleEntity.position = [-ctw/2, 0, 0]
            
            // Container so we can billboard/animate
            let titleContainer = Entity()
            titleContainer.position = [0, 0, sheetSize.z * 0.52]
            titleContainer.addChild(centeredTitleEntity)
            titleContainer.name = "title_\(memory.id.uuidString)"
            textEntities[memory.id] = titleContainer
            containerEntity.addChild(titleContainer)
            
            // Stand sheet upright and lift so it sits on the plane
            containerEntity.position = [0, sheetSize.y * 0.5, 0]
            
            // Collision
            sheetEntity.generateCollisionShapes(recursive: true)
            borderEntity.generateCollisionShapes(recursive: true)
            
            // Anchor at memory position
            let anchor = AnchorEntity(world: memory.simdPosition)
            anchor.addChild(containerEntity)
            
            arView.scene.addAnchor(anchor)
            memoryEntities[memory.id] = anchor
            
            print("📄 Created sheet note '\(memory.title)' at position: \(memory.simdPosition)")
        }

        private func openEnvelopeAnimation(for memory: Memory, on arView: ARView) {
            // Repurpose as sheet emphasis animation
            guard let anchor = memoryEntities[memory.id] else { return }
            guard let sheet = anchor.findEntity(named: "sheet_\(memory.id.uuidString)") else { return }
            
            let parent = sheet.parent
            var target = sheet.transform
            // Gentle tilt toward camera and slight scale-up
            let tilt = simd_quatf(angle: -.pi/18, axis: [1, 0, 0])
            target.rotation = simd_normalize(tilt * sheet.transform.rotation)
            target.scale = sheet.transform.scale * 1.06
            sheet.move(to: target, relativeTo: parent, duration: 0.35, timingFunction: .easeInOut)
        }
        
        func attemptRelocalizationIfPossible() {
            guard let arView = arView,
                  let memory = memoryManager?.memories.first(where: { $0.worldMapData != nil }),
                  let data = memory.worldMapData else { return }
            do {
                let map = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
                runSession(with: map)
            } catch {
                print("❌ Failed to unarchive world map: \(error.localizedDescription)")
            }
        }
        
        private func runSession(with worldMap: ARWorldMap?) {
            guard let arView = arView else { return }
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal]
            configuration.environmentTexturing = .none
            if let map = worldMap {
                configuration.initialWorldMap = map
                DispatchQueue.main.async { [weak self] in
                    self?.arCoordinatorWrapper?.isRelocalizing = true
                }
            }
            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }

        private func getPositionInFrontOfCamera(distance: Float = 0.5) -> SIMD3<Float>? {
            guard let arView = arView,
                  let cameraTransform = arView.session.currentFrame?.camera.transform else {
                return nil
            }
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -distance
            let finalTransform = simd_mul(cameraTransform, translation)
            let p = finalTransform.columns.3
            return SIMD3<Float>(p.x, p.y, p.z)
        }
    }
}

#Preview {
    ContentView()
}
