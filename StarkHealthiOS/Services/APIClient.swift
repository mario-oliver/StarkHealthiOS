import Foundation

struct CreateUserPayload: Encodable {
    let id: String
    let email: String
    let firstName: String?
    let lastName: String?
}

enum APIClientError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case missingToken

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response."
        case .httpError(let statusCode, let message):
            return message ?? "Request failed with status \(statusCode)."
        case .missingToken:
            return "Authentication token unavailable."
        }
    }
}

struct APIClient {
    typealias TokenProvider = @Sendable () async throws -> String?

    private let baseURL: URL
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    var tokenProvider: TokenProvider?

    init(baseURL: URL = AppConfig.apiBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Users

    func createUser(token: String, payload: CreateUserPayload) async throws {
        try await requestVoid(path: "v1/users", method: "POST", body: payload, token: token)
    }

    // MARK: - Dogs

    func listDogs() async throws -> [DogRecord] {
        try await request(path: "v1/dogs").data
    }

    func createDog(_ input: CreateDogInput) async throws -> DogRecord {
        try await request(path: "v1/dogs", method: "POST", body: input).data
    }

    func getDog(_ dogId: String) async throws -> DogRecord {
        try await request(path: "v1/dogs/\(dogId)").data
    }

    func updateDog(_ dogId: String, input: UpdateDogInput) async throws -> DogRecord {
        try await request(path: "v1/dogs/\(dogId)", method: "PATCH", body: input).data
    }

    func getToday(_ dogId: String, date: String? = nil) async throws -> TodayPayload {
        var path = "v1/dogs/\(dogId)/today"
        if let date, let encoded = date.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            path += "?date=\(encoded)"
        }
        return try await request(path: path).data
    }

    func getHistory(_ dogId: String, page: Int = 1, limit: Int = 20) async throws -> HistoryPayload {
        try await request(path: "v1/dogs/\(dogId)/history?page=\(page)&limit=\(limit)").data
    }

    func getCalendar(_ dogId: String, month: String) async throws -> CalendarPayload {
        let encoded = month.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? month
        return try await request(path: "v1/dogs/\(dogId)/calendar?month=\(encoded)").data
    }

    func updateDailyAction(
        _ dogId: String,
        actionId: String,
        body: UpdateDailyActionBody
    ) async throws -> DailyCareActionRecord {
        try await request(path: "v1/dogs/\(dogId)/daily-actions/\(actionId)", method: "PATCH", body: body).data
    }

    func updateDailyActionStep(
        _ dogId: String,
        stepId: String,
        body: UpdateDailyActionStepBody
    ) async throws -> DailyCareActionStepRecord {
        try await request(path: "v1/dogs/\(dogId)/daily-action-steps/\(stepId)", method: "PATCH", body: body).data
    }

    func getCarePlan(_ dogId: String) async throws -> CarePlanPayload {
        try await request(path: "v1/dogs/\(dogId)/care-plan").data
    }

    func createCareAction(_ dogId: String, input: CreateCareActionInput) async throws -> CareActionRecord {
        try await request(path: "v1/dogs/\(dogId)/care-plan/actions", method: "POST", body: input).data
    }

    func updateCareAction(_ dogId: String, actionId: String, input: UpdateCareActionInput) async throws -> CareActionRecord {
        try await request(path: "v1/dogs/\(dogId)/care-plan/actions/\(actionId)", method: "PATCH", body: input).data
    }

    func deactivateCareAction(_ dogId: String, actionId: String) async throws -> CareActionRecord {
        try await request(path: "v1/dogs/\(dogId)/care-plan/actions/\(actionId)/deactivate", method: "PATCH").data
    }

    func createCareActionStep(_ dogId: String, actionId: String, input: CreateCareActionStepInput) async throws -> CareActionStepRecord {
        try await request(path: "v1/dogs/\(dogId)/care-plan/actions/\(actionId)/steps", method: "POST", body: input).data
    }

    func updateCareActionStep(_ dogId: String, actionId: String, stepId: String, input: UpdateCareActionStepInput) async throws -> CareActionStepRecord {
        try await request(path: "v1/dogs/\(dogId)/care-plan/actions/\(actionId)/steps/\(stepId)", method: "PATCH", body: input).data
    }

    func deactivateCareActionStep(_ dogId: String, actionId: String, stepId: String) async throws -> CareActionStepRecord {
        try await request(path: "v1/dogs/\(dogId)/care-plan/actions/\(actionId)/steps/\(stepId)/deactivate", method: "PATCH").data
    }

    func previewJoin(code: String) async throws -> JoinPreview {
        let encoded = code.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? code
        return try await request(path: "v1/dogs/join/preview?code=\(encoded)").data
    }

    func joinByShareCode(_ shareCode: String) async throws -> DogRecord {
        struct Body: Encodable { let shareCode: String }
        return try await request(path: "v1/dogs/join", method: "POST", body: Body(shareCode: shareCode)).data
    }

    func presignDogPhoto(contentType: String, contentLength: Int) async throws -> PresignDogPhotoResult {
        struct Body: Encodable {
            let contentType: String
            let contentLength: Int
        }
        return try await request(path: "v1/uploads/dog-photo/presign", method: "POST", body: Body(contentType: contentType, contentLength: contentLength)).data
    }

    func presignCareStepMedia(contentType: String, contentLength: Int) async throws -> PresignCareStepMediaResult {
        struct Body: Encodable {
            let contentType: String
            let contentLength: Int
        }
        return try await request(path: "v1/uploads/care-step-media/presign", method: "POST", body: Body(contentType: contentType, contentLength: contentLength)).data
    }

    func transcribeVoiceNote(_ dogId: String, wavData: Data, date: String?) async throws -> TranscribeVoiceNotePayload {
        var path = "v1/dogs/\(dogId)/voice-notes/transcribe"
        if let date, let encoded = date.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            path += "?date=\(encoded)"
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(wavData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        let token = try await resolveToken()
        var request = URLRequest(url: makeURL(path: path))
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try decoder.decode(APIResponse<TranscribeVoiceNotePayload>.self, from: data).data
    }

    // MARK: - Private

    private func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        token: String? = nil
    ) async throws -> APIResponse<T> {
        let resolvedToken: String
        if let token {
            resolvedToken = token
        } else {
            resolvedToken = try await resolveToken()
        }
        var urlRequest = URLRequest(url: makeURL(path: path))
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(resolvedToken)", forHTTPHeaderField: "Authorization")
        if let body {
            urlRequest.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response) = try await session.data(for: urlRequest)
        try validate(response: response, data: data)
        return try decoder.decode(APIResponse<T>.self, from: data)
    }

    private func requestVoid(
        path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        token: String? = nil
    ) async throws {
        let resolvedToken: String
        if let token {
            resolvedToken = token
        } else {
            resolvedToken = try await resolveToken()
        }
        var urlRequest = URLRequest(url: makeURL(path: path))
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(resolvedToken)", forHTTPHeaderField: "Authorization")
        if let body {
            urlRequest.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response) = try await session.data(for: urlRequest)
        try validate(response: response, data: data)
    }

    private func makeURL(path: String) -> URL {
        URL(string: path, relativeTo: baseURL)!.absoluteURL
    }

    private func resolveToken() async throws -> String {
        if let token = try await tokenProvider?(), !token.isEmpty {
            return token
        }
        throw APIClientError.missingToken
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        guard (200 ... 299).contains(httpResponse.statusCode) else {
            let message = (try? decoder.decode(APIErrorBody.self, from: data))?.message
            throw APIClientError.httpError(statusCode: httpResponse.statusCode, message: message)
        }
    }
}

struct UpdateDailyActionBody: Encodable {
    var status: DailyCareActionStatus?
    var notes: String?
    var tolerance: Tolerance?
    var issueObserved: Bool?
}

struct UpdateDailyActionStepBody: Encodable {
    var status: DailyCareActionStatus?
    var notes: String?
}

private struct APIErrorBody: Decodable {
    let message: String?
}

private struct AnyEncodable: Encodable {
    private let encodeValue: (Encoder) throws -> Void

    init(_ wrapped: any Encodable) {
        encodeValue = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeValue(encoder)
    }
}
