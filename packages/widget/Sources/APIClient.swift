import Foundation

actor APIClient {
    static let shared = APIClient()
    private let base = URL(string: "http://127.0.0.1:8000")!
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    func health() async -> Bool {
        guard let data = try? await fetch("health") else { return false }
        let resp = try? JSONDecoder().decode(HealthResponse.self, from: data)
        return resp?.status == "ok"
    }

    func config() async -> NudgeConfigInfo? {
        guard let data = try? await fetch("api/config") else { return nil }
        do {
            return try JSONDecoder().decode(NudgeConfigInfo.self, from: data)
        } catch {
            NSLog("[Nudge API] config decode error: \(error)")
            return nil
        }
    }

    func tasks() async -> [NudgeTask] {
        guard let data = try? await fetch("api/tasks") else { return [] }
        do {
            return try JSONDecoder().decode([NudgeTask].self, from: data)
        } catch {
            NSLog("[Nudge API] tasks decode error: \(error)")
            return []
        }
    }

    func alarms() async -> [NudgeAlarm] {
        guard let data = try? await fetch("api/alarms") else { return [] }
        do {
            return try JSONDecoder().decode([NudgeAlarm].self, from: data)
        } catch {
            NSLog("[Nudge API] alarms decode error: \(error)")
            return []
        }
    }

    func notes(limit: Int = 20) async -> [APINote] {
        guard let data = try? await fetch("api/notes") else { return [] }
        do {
            return try JSONDecoder().decode([APINote].self, from: data)
        } catch {
            NSLog("[Nudge API] notes decode error: \(error)")
            return []
        }
    }

    func history() async -> [SessionEntry] {
        guard let data = try? await fetch("api/history") else { return [] }
        do {
            return try JSONDecoder().decode([SessionEntry].self, from: data)
        } catch {
            NSLog("[Nudge API] history decode error: \(error)")
            return []
        }
    }

    func processText(_ text: String) async -> SessionResult? {
        let url = base.appendingPathComponent("api/process")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["text": text])

        guard let (data, _) = try? await session.data(for: request) else { return nil }
        do {
            return try JSONDecoder().decode(SessionResult.self, from: data)
        } catch {
            NSLog("[Nudge API] processText decode error: \(error)")
            return nil
        }
    }

    func processAudio(_ audioData: Data, sampleRate: Int = 16000) async -> SessionResult? {
        let url = base.appendingPathComponent("api/process-audio")
        let boundary = UUID().uuidString

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.raw\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"sample_rate\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(sampleRate)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        NSLog("[Nudge API] Sending \(audioData.count) bytes to process-audio sampleRate=\(sampleRate)")
        guard let (data, resp) = try? await session.data(for: request) else {
            NSLog("[Nudge API] process-audio request failed")
            return nil
        }
        if let httpResp = resp as? HTTPURLResponse {
            NSLog("[Nudge API] process-audio status: \(httpResp.statusCode)")
        }
        do {
            return try JSONDecoder().decode(SessionResult.self, from: data)
        } catch {
            NSLog("[Nudge API] processAudio decode error: \(error)")
            if let raw = String(data: data, encoding: .utf8) {
                NSLog("[Nudge API] Raw response: \(raw.prefix(500))")
            }
            return nil
        }
    }

    func transcribeAudio(_ audioData: Data, sampleRate: Int = 16000) async -> String? {
        let url = base.appendingPathComponent("api/transcribe")
        let boundary = UUID().uuidString

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.raw\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"sample_rate\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(sampleRate)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        NSLog("[Nudge API] Sending %d bytes to transcribe sampleRate=%d", audioData.count, sampleRate)
        guard let (data, resp) = try? await session.data(for: request) else {
            NSLog("[Nudge API] transcribe request failed (network error or server unreachable)")
            return nil
        }
        if let httpResp = resp as? HTTPURLResponse {
            NSLog("[Nudge API] transcribe status: %d", httpResp.statusCode)
        }
        struct TranscribeResponse: Codable { let text: String }
        do {
            let decoded = try JSONDecoder().decode(TranscribeResponse.self, from: data)
            NSLog("[Nudge API] transcribe result: %@", decoded.text.prefix(200).description)
            return decoded.text
        } catch {
            NSLog("[Nudge API] transcribe decode error: %@", error.localizedDescription)
            if let raw = String(data: data, encoding: .utf8) {
                NSLog("[Nudge API] transcribe raw response: %@", raw.prefix(500).description)
            }
            return nil
        }
    }

    // MARK: - Stats & Config

    func stats() async -> NudgeStats? {
        guard let data = try? await fetch("api/stats") else { return nil }
        do {
            return try JSONDecoder().decode(NudgeStats.self, from: data)
        } catch {
            NSLog("[Nudge API] stats decode error: \(error)")
            return nil
        }
    }

    func configFull() async -> ConfigFull? {
        guard let data = try? await fetch("api/config/full") else { return nil }
        do {
            return try JSONDecoder().decode(ConfigFull.self, from: data)
        } catch {
            NSLog("[Nudge API] config/full decode error: \(error)")
            return nil
        }
    }

    /// POST /api/config with only the changed fields. Returns true on 200.
    func saveConfig(_ fields: [String: String]) async -> Bool {
        await postJSONOK("api/config", body: fields)
    }

    /// POST /api/config/keys. Returns true on 200.
    func saveKey(provider: String, apiKey: String) async -> Bool {
        await postJSONOK("api/config/keys", body: ["provider": provider, "api_key": apiKey])
    }

    /// GET /api/links — saved named links.
    func links() async -> [NamedLink] {
        guard let data = try? await fetch("api/links") else { return [] }
        return (try? JSONDecoder().decode([NamedLink].self, from: data)) ?? []
    }

    /// POST /api/links. Returns true on 200.
    func saveLink(name: String, url: String) async -> Bool {
        await postJSONOK("api/links", body: ["name": name, "url": url])
    }

    /// DELETE /api/links/{name}. Returns true on 200.
    func deleteLink(_ name: String) async -> Bool {
        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
        return await delete("api/links/\(encoded)")
    }

    /// GET /api/soul — the persona/instructions markdown.
    func soul() async -> String? {
        guard let data = try? await fetch("api/soul") else { return nil }
        struct SoulResponse: Codable { let content: String }
        return (try? JSONDecoder().decode(SoulResponse.self, from: data))?.content
    }

    /// POST /api/soul. Returns true on 200.
    func saveSoul(_ content: String) async -> Bool {
        await postJSONOK("api/soul", body: ["content": content])
    }

    /// POST /api/validate — runs a real test call on the backend.
    func validate(provider: String, kind: String, apiKey: String?) async -> ValidateResult {
        var body: [String: String] = ["provider": provider, "kind": kind]
        if let apiKey, !apiKey.isEmpty { body["api_key"] = apiKey }
        guard let result: ValidateResult = await postJSON("api/validate", body: body) else {
            return ValidateResult(ok: false, message: "Could not reach the Nudge server")
        }
        return result
    }

    // MARK: - Actions

    func completeTask(_ taskId: String) async -> Bool {
        return await post("api/tasks/\(taskId)/complete", label: "complete task \(taskId)")
    }

    func uncompleteTask(_ taskId: String) async -> Bool {
        return await post("api/tasks/\(taskId)/uncomplete", label: "uncomplete task \(taskId)")
    }

    func deleteTask(_ taskId: String) async -> Bool {
        return await delete("api/tasks/\(taskId)")
    }

    func cancelAlarm(_ alarmId: String) async -> Bool {
        return await delete("api/alarms/\(alarmId)")
    }

    func deleteNote(_ noteId: String) async -> Bool {
        return await delete("api/notes/\(noteId)")
    }

    func doneTasks() async -> [NudgeTask] {
        var components = URLComponents(
            url: base.appendingPathComponent("api/tasks"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "status", value: "done")]
        guard let url = components.url,
              let (data, _) = try? await session.data(from: url)
        else { return [] }
        do {
            return try JSONDecoder().decode([NudgeTask].self, from: data)
        } catch {
            NSLog("[Nudge API] done tasks decode error: \(error)")
            return []
        }
    }

    // MARK: - HTTP Helpers

    private func post(_ path: String, label: String = "post") async -> Bool {
        let url = base.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        do {
            let (data, resp) = try await session.data(for: request)
            let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
            let raw = String(data: data, encoding: .utf8) ?? ""
            NSLog("[Nudge API] %@ status=%d response=%@", label, status, raw.prefix(240).description)
            return status == 200
        } catch {
            NSLog("[Nudge API] %@ failed: %@", label, error.localizedDescription)
            return false
        }
    }

    private func delete(_ path: String) async -> Bool {
        let url = base.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        guard let (_, resp) = try? await session.data(for: request) else { return false }
        return (resp as? HTTPURLResponse)?.statusCode == 200
    }

    private func fetch(_ path: String) async throws -> Data {
        let url = base.appendingPathComponent(path)
        let (data, _) = try await session.data(from: url)
        return data
    }

    /// POST a JSON body and decode the response into T. Returns nil on any failure.
    private func postJSON<T: Decodable>(_ path: String, body: [String: String]) async -> T? {
        let url = base.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)
        guard let (data, _) = try? await session.data(for: request) else { return nil }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            NSLog("[Nudge API] postJSON \(path) decode error: \(error)")
            return nil
        }
    }

    /// POST a JSON body and return whether the status was 200.
    private func postJSONOK(_ path: String, body: [String: String]) async -> Bool {
        let url = base.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)
        guard let (_, resp) = try? await session.data(for: request) else { return false }
        return (resp as? HTTPURLResponse)?.statusCode == 200
    }
}
