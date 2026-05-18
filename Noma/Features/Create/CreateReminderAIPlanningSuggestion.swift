import Foundation

struct AIPlanningSuggestion: Decodable {
    let summary: String
    let focusReminderID: String?
    let carryForwardReminderIDs: [String]
    let deferredReminderIDs: [String]

    static func decode(from response: String) throws -> AIPlanningSuggestion? {
        guard let data = FoundationModelJSONExtractor.jsonObjectData(from: response) else { return nil }
        return try JSONDecoder().decode(AIPlanningSuggestion.self, from: data)
    }
}
