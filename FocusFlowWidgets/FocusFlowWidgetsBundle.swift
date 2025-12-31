import WidgetKit
import SwiftUI

@main
struct FocusFlowWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // Combined Home Screen Widget (supports Small + Medium)
        FocusFlowWidget()
        
        // Live Activity widget (iOS 18+)
        if #available(iOSApplicationExtension 18.0, *) {
            FocusSessionLiveActivity()
        }
    }
}
