import Foundation

enum FoundationModelJSONExtractor {
    static func jsonObjectData(from response: String) -> Data? {
        let trimmedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if let data = trimmedResponse.data(using: .utf8), canDecodeJSON(from: data) {
            return data
        }

        guard let startIndex = trimmedResponse.firstIndex(of: "{") else { return nil }
        return balancedJSONObjectData(in: trimmedResponse, startingAt: startIndex)
    }

    private static func balancedJSONObjectData(
        in text: String,
        startingAt startIndex: String.Index
    ) -> Data? {
        var state = FoundationModelJSONScanState()

        for index in text.indices[startIndex...] {
            state.scan(text[index])
            if state.didCloseRootObject {
                return String(text[startIndex...index]).data(using: .utf8)
            }
        }

        return nil
    }

    private static func canDecodeJSON(from data: Data) -> Bool {
        (try? JSONSerialization.jsonObject(with: data)) != nil
    }
}

private struct FoundationModelJSONScanState {
    private(set) var depth = 0
    private var isInsideString = false
    private var isEscaped = false

    var didCloseRootObject: Bool { depth == 0 }

    mutating func scan(_ character: Character) {
        if isEscaped {
            isEscaped = false
            return
        }

        if character == "\\" {
            isEscaped = isInsideString
            return
        }

        if character == "\"" {
            isInsideString.toggle()
            return
        }

        guard !isInsideString else { return }

        if character == "{" {
            depth += 1
        } else if character == "}" {
            depth -= 1
        }
    }
}
