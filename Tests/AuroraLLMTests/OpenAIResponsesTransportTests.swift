import XCTest
@testable import AuroraLLM

final class OpenAIResponsesTransportTests: XCTestCase {
    override class func setUp() {
        super.setUp()
    }

    func makeSession(handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data)) -> URLSession {
        MockURLProtocol.requestHandler = handler
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    func testResponsesTransportSendsInputBody() async throws {
        let expectedBodyKey = "input"

        let session = makeSession { request in
            XCTAssertEqual(request.url?.path, "/v1/responses")
            // URLSession may copy the request, so check both httpBody and httpBodyStream
            let bodyData: Data
            if let httpBody = request.httpBody {
                bodyData = httpBody
            } else if let stream = request.httpBodyStream {
                bodyData = try Data(reading: stream)
            } else {
                throw XCTSkip("Request body not available in httpBody or stream")
            }
            let json = try JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any]
            XCTAssertNotNil(json?[expectedBodyKey])
            let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let payload = Self.responsesMinimalJSON(text: "hello")
            return (resp, payload)
        }

        let service = OpenAIService(apiKey: "dummy", urlSession: session, logger: nil)
        let req = LLMRequest(
            messages: [.init(role: .user, content: "Say hi")],
            model: "gpt-5-nano",
            stream: false
        )
        let resp = try await service.sendRequest(req)
        XCTAssertEqual(resp.text, "hello")
    }

    func testLegacyChatTransportSendsMessagesBody() async throws {
        let session = makeSession { request in
            XCTAssertEqual(request.url?.path, "/v1/chat/completions")
            // URLSession may copy the request, so check both httpBody and httpBodyStream
            let bodyData: Data
            if let httpBody = request.httpBody {
                bodyData = httpBody
            } else if let stream = request.httpBodyStream {
                bodyData = try Data(reading: stream)
            } else {
                throw XCTSkip("Request body not available in httpBody or stream")
            }
            let json = try JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any]
            XCTAssertNotNil(json?["messages"])
            let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let payload = Self.chatMinimalJSON(text: "ok")
            return (resp, payload)
        }

        let service = OpenAIService(apiKey: "dummy", urlSession: session, logger: nil)
        let opts = LLMRequestOptions(transport: .legacyChat)
        let req = LLMRequest(
            messages: [.init(role: .user, content: "Ping")],
            model: "gpt-4o-mini",
            stream: false,
            options: opts
        )
        let resp = try await service.sendRequest(req)
        XCTAssertEqual(resp.text, "ok")
    }

    // MARK: - Helpers

    static func responsesMinimalJSON(text: String) -> Data {
        let json: [String: Any] = [
            "id": "resp_123",
            "model": "gpt-5-nano",
            "output": [
                [
                    "content": [["type": "output_text", "text": text]]
                ]
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json, options: [])
    }

    static func chatMinimalJSON(text: String) -> Data {
        let json: [String: Any] = [
            "id": "chatcmpl_123",
            "object": "chat.completion",
            "choices": [
                [
                    "index": 0,
                    "message": ["role": "assistant", "content": text],
                    "finish_reason": "stop"
                ]
            ],
            "usage": ["prompt_tokens": 0, "completion_tokens": 0, "total_tokens": 0],
            "model": "gpt-4o-mini"
        ]
        return try! JSONSerialization.data(withJSONObject: json, options: [])
    }
}

extension Data {
    init(reading stream: InputStream) throws {
        stream.open()
        defer { stream.close() }
        var data = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let bytesRead = stream.read(buffer, maxLength: 1024)
            if bytesRead > 0 {
                data.append(buffer, count: bytesRead)
            } else if bytesRead < 0 {
                throw stream.streamError ?? NSError(domain: "StreamError", code: -1)
            }
        }
        self = data
    }
}

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else { fatalError("No handler set") }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}


