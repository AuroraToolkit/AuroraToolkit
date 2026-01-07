import XCTest
@testable import AuroraLLM

final class OllamaServiceTests: XCTestCase {

    func makeSession(handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data)) -> URLSession {
        MockURLProtocol.requestHandler = handler
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    func testSendRequestSendsChatBody() async throws {
        let session = makeSession { request in
            XCTAssertEqual(request.url?.path, "/api/chat")
            XCTAssertEqual(request.httpMethod, "POST")
            
            let bodyData: Data
            if let httpBody = request.httpBody {
                bodyData = httpBody
            } else if let stream = request.httpBodyStream {
                bodyData = try Data(reading: stream)
            } else {
                XCTFail("Request body not available")
                return (HTTPURLResponse(), Data())
            }
            let json = try JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any]
            
            XCTAssertNotNil(json?["messages"])
            XCTAssertEqual((json?["messages"] as? [[String: String]])?.count, 1)
            XCTAssertEqual((json?["messages"] as? [[String: String]])?[0]["role"], "user")
            XCTAssertEqual((json?["messages"] as? [[String: String]])?[0]["content"], "Hello")
            XCTAssertEqual(json?["model"] as? String, "gemma3")
            
            let options = json?["options"] as? [String: Any]
            XCTAssertNotNil(options)
            XCTAssertEqual(options?["temperature"] as? Double, 0.7)
            XCTAssertEqual(options?["num_predict"] as? Int, 256)
            
            let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let payload = """
            {
                "model": "gemma3",
                "created_at": "2023-08-04T08:52:19.385406455Z",
                "message": {
                    "role": "assistant",
                    "content": "Hello there!"
                },
                "done": true,
                "total_duration": 4883583458,
                "load_duration": 1334801,
                "prompt_eval_count": 20,
                "prompt_eval_duration": 13139000,
                "eval_count": 20,
                "eval_duration": 4869092000
            }
            """.data(using: .utf8)!
            return (resp, payload)
        }

        let service = OllamaService(baseURL: "http://localhost:11434", urlSession: session)
        let req = LLMRequest(messages: [LLMMessage(role: .user, content: "Hello")])
        let resp = try await service.sendRequest(req)
        
        XCTAssertEqual(resp.text, "Hello there!")
        XCTAssertEqual(resp.vendor, "Ollama")
        XCTAssertEqual(resp.model, "gemma3")
        XCTAssertEqual(resp.tokenUsage?.promptTokens, 20)
        XCTAssertEqual(resp.tokenUsage?.completionTokens, 20)
        XCTAssertEqual(resp.tokenUsage?.totalTokens, 40)
    }
    
    func testSendRequestWithMultipleMessages() async throws {
        let session = makeSession { request in
            let bodyData: Data
            if let httpBody = request.httpBody {
                bodyData = httpBody
            } else if let stream = request.httpBodyStream {
                bodyData = try Data(reading: stream)
            } else {
                XCTFail("Request body not available")
                return (HTTPURLResponse(), Data())
            }
            let json = try JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any]
            let messages = json?["messages"] as? [[String: String]]
            
            XCTAssertEqual(messages?.count, 2)
            XCTAssertEqual(messages?[0]["role"], "system")
            XCTAssertEqual(messages?[0]["content"], "You are a helper")
            XCTAssertEqual(messages?[1]["role"], "user")
            XCTAssertEqual(messages?[1]["content"], "Hi")
            
            let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let payload = """
            {
                "model": "gemma3",
                "message": { "role": "assistant", "content": "Hello!" },
                "done": true
            }
            """.data(using: .utf8)!
            return (resp, payload)
        }

        let service = OllamaService(baseURL: "http://localhost:11434", urlSession: session)
        let req = LLMRequest(messages: [
            LLMMessage(role: .system, content: "You are a helper"),
            LLMMessage(role: .user, content: "Hi")
        ])
        let resp = try await service.sendRequest(req)
        XCTAssertEqual(resp.text, "Hello!")
    }
}


