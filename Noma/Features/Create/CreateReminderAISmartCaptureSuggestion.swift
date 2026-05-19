import Foundation

struct SmartCaptureSuggestion: Decodable {
    let title: String
    let projectID: String?
    let projectTitle: String?

    static func decode(from response: String) throws -> SmartCaptureSuggestion? {
        guard let data = FoundationModelJSONExtractor.jsonObjectData(from: response) else { return nil }
        return try JSONDecoder().decode(SmartCaptureSuggestion.self, from: data)
    }
}
