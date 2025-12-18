import Foundation
import SwiftUI

struct FocusNotification: Identifiable, Codable, Hashable {
    enum Kind: String, Codable {
        case sessionCompleted
        case streak
        case habit
        case general
    }

    let id: UUID
    let kind: Kind
    let title: String
    let body: String
    let date: Date
    var isRead: Bool

    init(
        id: UUID = UUID(),
        kind: Kind,
        title: String,
        body: String,
        date: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.date = date
        self.isRead = isRead
    }

    // MARK: - Presentation helpers

    /// Neutral, focus-y icons (no hard-coded colors)
    var iconName: String {
        switch kind {
        case .sessionCompleted: return "sparkles"
        case .streak:           return "flame.fill"
        case .habit:            return "checkmark.circle"
        case .general:          return "bell.fill"
        }
    }

    var relativeDateString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
