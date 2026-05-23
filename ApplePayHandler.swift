import SwiftUI
import UIKit

// MARK: - ApplePayHandler

class ApplePayHandler: NSObject {

    static let shared = ApplePayHandler()

    static var isAvailable: Bool { true }

    var onSuccess: (() -> Void)?
    var onFinish:  (() -> Void)?

    func presentPayment(
        cardName:  String,
        storeName: String,
        amount: NSDecimalNumber = NSDecimalNumber(string: "50.00"),
        onSuccess: @escaping () -> Void
    ) {
        self.onSuccess = onSuccess

        var vc: UIHostingController<ApplePaySimulatorSheet>?

        vc = UIHostingController(
            rootView: ApplePaySimulatorSheet(
                cardName:  cardName,
                storeName: storeName
            ) { [weak self] approved in
                vc?.dismiss(animated: true)
                vc = nil
                if approved {
                    self?.onSuccess?()
                    self?.onSuccess = nil
                }
                self?.onFinish?()
                self?.onFinish = nil
            }
        )

        guard let vc else { return }
        vc.modalPresentationStyle = .overFullScreen
        vc.view.backgroundColor   = .clear

        DispatchQueue.main.async {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows.first?.rootViewController?
                .present(vc, animated: true)
        }
    }
}

// MARK: - ApplePaySimulatorSheet

struct ApplePaySimulatorSheet: View {
    let cardName:  String
    let storeName: String
    let onDone: (Bool) -> Void

    @State private var confirmed = false
    @State private var visible   = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { onDone(false) }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Handle
                    Capsule()
                        .fill(Color(.systemGray4))
                        .frame(width: 36, height: 4)
                        .padding(.top, 10)
                        .padding(.bottom, 18)

                    // Apple Pay header
                    HStack(spacing: 6) {
                        Image(systemName: "applelogo")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Pay")
                            .font(.system(size: 22, weight: .semibold))
                    }
                    .padding(.bottom, 20)

                    // Merchant row
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(storeName)
                                .font(.system(size: 16, weight: .medium))
                            Text("Tap to pay at checkout")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                    Divider()

                    // Card row
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "1A56DB"), Color(hex: "0A3D8F")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 30)
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cardName)
                                .font(.system(size: 14, weight: .medium))
                            Text("Best card for \(storeName)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 20))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    Divider()

                    // Confirm / success
                    if confirmed {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 22))
                            Text("Payment Approved")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 22)
                    } else {
                        Button {
                            confirmed = true
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                onDone(true)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "applelogo")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Pay")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.black)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }

                    Color.clear.frame(height: 20)
                }
                .background(Color(.systemBackground))
                .cornerRadius(20, corners: [.topLeft, .topRight])
            }
        }
        .opacity(visible ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.22)) { visible = true }
        }
    }
}

// MARK: - Helpers

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius:  CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}
