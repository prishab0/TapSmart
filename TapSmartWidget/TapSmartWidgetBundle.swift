import WidgetKit
import SwiftUI

@main
struct TapSmartWidgetBundle: WidgetBundle {
    var body: some Widget {
        TapSmartWidget()            // small + medium home screen
        TapSmartLargeWidget()       // large home screen (chart + recent transactions)
        TapSmartLockScreenWidget()  // accessoryRectangular + Circular + Inline
    }
}
