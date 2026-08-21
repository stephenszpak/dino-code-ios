import UIKit

/// Thin wrapper around `UINotificationFeedbackGenerator` so call sites read
/// as "success"/"error" rather than remembering which generator to spin up.
enum HapticsManager {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
