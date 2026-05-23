import SwiftUI
import UIKit

// MARK: - ActivityView
// UIViewControllerRepresentable wrapper around UIActivityViewController.
// Used in SavingsView to share a savings summary via the system share sheet.
//
// Usage:
//   .sheet(isPresented: $showShare) {
//       ActivityView(activityItems: [SavingsSummaryShareSheet.summary(from: store)])
//   }

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}
