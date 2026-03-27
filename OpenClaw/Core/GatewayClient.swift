import Foundation
import os

// MARK: - Protocol (Dependency Inversion)

/// Abstraction over gateway networking — ViewModels depend on this, not concrete types.
protocol GatewayClientProtocol: Sendable {
    func stats<Response: Decodable>(_ path: String) async throws -> Response
    func invoke<Body: Encodable, Response: Decodable>(_ body: Body) async throws -> Response
}

// MARK: - Implementation

/// Thread-safe gateway HTTP client.
/// All stored properties are immutable and Sendable — no @unchecked needed.
struct GatewayClient: GatewayClientProtocol, Sendable {
    private static let baseURL = URL(string: "https://api.appwebdev.co.uk")!
    private static let invokeURL = baseURL.appending(path: "tools/invoke")
    private static let logger = Logger(subsystem: "co.uk.appwebdev.openclaw", category: "Gateway")

    let keychain: KeychainService

    init(keychain: KeychainService = KeychainService()) {
        self.keychain = keychain
    }

    // MARK: - GET /stats/*  (plain JSON, no envelope)

    func stats<Response: Decodable>(_ path: String) async throws -> Response {
        let token = try requireToken()

        let url = Self.baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        Self.logger.debug("GET /\(path)")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data, path: path)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(Response.self, from: data)
    }

    // MARK: - POST /tools/invoke  (wrapped: result.content[0].text → JSON string)

    func invoke<Body: Encodable, Response: Decodable>(
        _ body: Body
    ) async throws -> Response {
        let token = try requireToken()

        var request = URLRequest(url: Self.invokeURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        Self.logger.debug("POST /tools/invoke")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data, path: "tools/invoke")

        let envelope = try JSONDecoder().decode(GatewayResponse.self, from: data)
        guard let text = envelope.result.content.first?.text,
              let jsonData = text.data(using: .utf8) else {
            throw GatewayError.emptyContent
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(Response.self, from: jsonData)
    }

    // MARK: - Private helpers

    private func requireToken() throws -> String {
        guard let token = keychain.readToken() else {
            throw GatewayError.noToken
        }
        return token
    }

    private func validateHTTPResponse(_ response: URLResponse, data: Data, path: String) throws {
        guard let http = response as? HTTPURLResponse else {
            throw GatewayError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            if let envelope = try? JSONDecoder().decode(GatewayErrorEnvelope.self, from: data),
               let detail = envelope.error {
                Self.logger.error("\(http.statusCode) /\(path) — \(detail.message)")
                throw GatewayError.serverError(http.statusCode, type: detail.type, message: detail.message)
            }
            Self.logger.error("\(http.statusCode) /\(path)")
            throw GatewayError.httpError(http.statusCode, body: body)
        }
    }
}
