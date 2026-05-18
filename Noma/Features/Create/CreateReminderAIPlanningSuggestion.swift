import Foundation

struct AIPlanningSuggestion: Decodable {
    let taskOrganization: [OrganizedTask]
    let carryForwardReminderIDs: [String]

    struct OrganizedTask: Decodable {
        let id: String
        let priorityRank: Int
        let category: String
    }

    static func decode(from response: String) throws -> AIPlanningSuggestion? {
        guard let data = FoundationModelJSONExtractor.jsonObjectData(from: response) else { return nil }
        return try JSONDecoder().decode(AIPlanningSuggestion.self, from: data)
    }
}
