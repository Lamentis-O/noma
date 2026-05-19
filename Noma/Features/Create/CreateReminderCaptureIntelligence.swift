import Foundation

struct CreateReminderCaptureIntent: Equatable {
    let normalizedText: String
    let projectID: TaskProject.ID?
}

enum CreateReminderCaptureIntelligence {
    static func intent(from text: String, projects: [TaskProject]) -> CreateReminderCaptureIntent {
        let normalizedText = CreateReminderSubmission.normalizedText(from: text)
        guard !normalizedText.isEmpty else {
            return CreateReminderCaptureIntent(normalizedText: "", projectID: nil)
        }

        if let explicitProject = explicitProject(in: normalizedText, projects: projects) {
            return explicitProject
        }

        return CreateReminderCaptureIntent(normalizedText: normalizedText, projectID: nil)
    }

    private static func explicitProject(
        in normalizedText: String,
        projects: [TaskProject]
    ) -> CreateReminderCaptureIntent? {
        for project in projects {
            if let intent = hashIntent(for: project, in: normalizedText) {
                return intent
            }

            if let intent = bracketIntent(for: project, in: normalizedText) {
                return intent
            }

            if let intent = prefixIntent(for: project, in: normalizedText) {
                return intent
            }
        }

        return nil
    }

    private static func hashIntent(
        for project: TaskProject,
        in normalizedText: String
    ) -> CreateReminderCaptureIntent? {
        guard let markerRange = CreateReminderHashProjectMarker.range(for: project, in: normalizedText) else { return nil }
        let cleanedText = normalizedText.replacingCharacters(in: markerRange, with: "")

        return cleanedIntent(cleanedText: cleanedText, projectID: project.id)
    }

    private static func bracketIntent(
        for project: TaskProject,
        in normalizedText: String
    ) -> CreateReminderCaptureIntent? {
        anchoredIntent(marker: "[\(project.title)]", projectID: project.id, in: normalizedText)
    }

    private static func prefixIntent(
        for project: TaskProject,
        in normalizedText: String
    ) -> CreateReminderCaptureIntent? {
        anchoredIntent(marker: "\(project.title):", projectID: project.id, in: normalizedText)
    }

    private static func anchoredIntent(
        marker: String,
        projectID: TaskProject.ID,
        in normalizedText: String
    ) -> CreateReminderCaptureIntent? {
        guard let markerRange = normalizedText.range(
            of: marker,
            options: [.anchored, .caseInsensitive, .diacriticInsensitive]
        ) else { return nil }
        let cleanedText = String(normalizedText[markerRange.upperBound...])

        return cleanedIntent(cleanedText: cleanedText, projectID: projectID)
    }

    private static func cleanedIntent(
        cleanedText: String,
        projectID: TaskProject.ID
    ) -> CreateReminderCaptureIntent? {
        let normalizedText = CreateReminderSubmission.normalizedText(from: cleanedText)
        guard !normalizedText.isEmpty else { return nil }

        return CreateReminderCaptureIntent(normalizedText: normalizedText, projectID: projectID)
    }
}

enum CreateReminderHashProjectMarker {
    static func range(for project: TaskProject, in normalizedText: String) -> Range<String.Index>? {
        let marker = "#\(markerTitle(for: project))"
        var searchRange: Range<String.Index>? = normalizedText.startIndex..<normalizedText.endIndex
        while let markerRange = normalizedText.range(
            of: marker,
            options: [.caseInsensitive, .diacriticInsensitive],
            range: searchRange
        ) {
            if hasBoundary(after: markerRange, in: normalizedText) {
                return markerRange
            }
            searchRange = markerRange.upperBound..<normalizedText.endIndex
        }

        return nil
    }

    private static func hasBoundary(after markerRange: Range<String.Index>, in text: String) -> Bool {
        guard markerRange.upperBound < text.endIndex else { return true }
        return text[markerRange.upperBound].unicodeScalars.allSatisfy {
            !CharacterSet.alphanumerics.contains($0)
        }
    }

    private static func markerTitle(for project: TaskProject) -> String {
        project.title
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined()
    }
}
