//
//  MeshyService.swift
//  AR Journal Memory
//
//  Minimal client for Meshy.ai text-to-3D → USDZ generation
//

import Foundation

struct MeshyService {
    struct CreateTaskResponse: Decodable { let task_id: String }
    struct TaskResult: Decodable { let usdz_url: String? }
    struct TaskStatusResponse: Decodable { let status: String; let result: TaskResult? }

    enum ServiceError: Error { case missingApiKey, invalidURL, badResponse, failedTask(String), missingUSDZ }

    private static let baseURL = URL(string: "https://api.meshy.ai")!

    private static var apiKey: String? {
        let env = ProcessInfo.processInfo.environment["MESHY_API_KEY"]
        if let env, !env.isEmpty { return env }
        // Fallback constant (fill if you prefer hardcoding)
        return nil
    }

    static func createTextTo3DTask(prompt: String) async throws -> String {
        guard let apiKey = apiKey else { throw ServiceError.missingApiKey }
        let url = baseURL.appendingPathComponent("text-to-3d")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "prompt": prompt,
            "mode": "preview"  // preview is faster; adjust if needed
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw ServiceError.badResponse }
        let decoded = try JSONDecoder().decode(CreateTaskResponse.self, from: data)
        return decoded.task_id
    }

    static func pollTaskUntilComplete(taskId: String, pollInterval: TimeInterval = 5) async throws -> URL {
        guard let apiKey = apiKey else { throw ServiceError.missingApiKey }
        let url = baseURL.appendingPathComponent("tasks/\(taskId)")
        while true {
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw ServiceError.badResponse }
            let status = try JSONDecoder().decode(TaskStatusResponse.self, from: data)
            if status.status.lowercased() == "completed" {
                guard let s = status.result?.usdz_url, let remote = URL(string: s) else { throw ServiceError.missingUSDZ }
                return remote
            }
            if status.status.lowercased() == "failed" {
                throw ServiceError.failedTask("Task failed on Meshy.ai")
            }
            try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }
    }

    static func downloadUSDZ(from remoteURL: URL) async throws -> URL {
        let (data, resp) = try await URLSession.shared.data(from: remoteURL)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw ServiceError.badResponse }
        let caches = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = caches.appendingPathComponent("GeneratedAssets", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        let filename = UUID().uuidString + ".usdz"
        let local = dir.appendingPathComponent(filename)
        try data.write(to: local, options: [.atomic])
        return local
    }
}


