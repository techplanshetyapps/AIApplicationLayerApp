import Foundation

/// Talks to your deployed ai-application-layer instance (e.g. https://ai-application-layer.vercel.app).

struct APIClient {

    static var baseURL = URL(string: "https://ai-application-layer.vercel.app")!


    struct HealthResponse: Decodable {
        let ok: Bool
        let gemmaModel: String?
        let vectorCount: Int?
        let error: String?
    }

    static func health() async throws -> HealthResponse {
        let (data, _) = try await URLSession.shared.data(from: baseURL.appendingPathComponent("api/health"))
        return try JSONDecoder().decode(HealthResponse.self, from: data)
    }


    struct IngestResponse: Decodable {
        let message: String
        let articlesIngested: Int
        let chunksIngested: Int
        let sample: [String]
    }

    static func ingest(limit: Int = 10, split: String = "test") async throws -> IngestResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("api/ingest"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["limit": limit, "split": split]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.throwIfServerError(data: data, response: response)
        return try JSONDecoder().decode(IngestResponse.self, from: data)
    }

    struct QuerySource: Decodable {
        let title: String?
        let sourceId: String?
        let distance: Double?
    }

    struct QueryResponse: Decodable {
        let answer: String
        let provider: String?
        let model: String?
        let sources: [QuerySource]
    }

    static func query(_ question: String, topK: Int = 5) async throws -> QueryResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("api/query"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["question": question, "topK": topK])

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.throwIfServerError(data: data, response: response)
        return try JSONDecoder().decode(QueryResponse.self, from: data)
    }

    private struct ErrorPayload: Decodable { let error: String? }

    private static func throwIfServerError(data: Data, response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) else { return }
        let message = (try? JSONDecoder().decode(ErrorPayload.self, from: data))?.error
            ?? "Server returned status \(http.statusCode)"
        throw NSError(domain: "APIClient", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
