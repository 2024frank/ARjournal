//
//  MemoryManager.swift
//  AR Journal Memory
//
//  Manages memory persistence and storage
//

import Foundation
import Combine

class MemoryManager: ObservableObject {
    @Published var memories: [Memory] = []
    
    private let storageKey = "SavedMemories"
    
    init() {
        loadMemories()
    }
    
    // Add a new memory
    func addMemory(_ memory: Memory) {
        memories.append(memory)
        saveMemories()
        print("✅ Memory saved: '\(memory.title)'")
    }
    
    // Save memories to UserDefaults
    private func saveMemories() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(memories)
            UserDefaults.standard.set(data, forKey: storageKey)
            print("💾 Saved \(memories.count) memories to storage")
        } catch {
            print("❌ Failed to save memories: \(error)")
        }
    }
    
    // Load memories from UserDefaults
    private func loadMemories() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            print("📂 No saved memories found")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            memories = try decoder.decode([Memory].self, from: data)
            print("📂 Loaded \(memories.count) memories from storage")
        } catch {
            print("❌ Failed to load memories: \(error)")
        }
    }
    
    // Clear all memories (for testing)
    func clearAllMemories() {
        memories.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
        print("🗑️ All memories cleared")
    }

    // Delete a single memory
    func deleteMemory(id: UUID) {
        if let index = memories.firstIndex(where: { $0.id == id }) {
            let title = memories[index].title
            memories.remove(at: index)
            saveMemories()
            print("🗑️ Deleted memory: '\(title)'")
        }
    }
}
