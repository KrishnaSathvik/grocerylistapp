import SwiftUI
import VisionKit

struct QRScannerScreen: View {
    @Environment(\.dismiss) private var dismiss
    let onScan: (String) -> Void

    private var isScannerAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    var body: some View {
        NavigationStack {
            Group {
                if isScannerAvailable {
                    QRScannerRepresentable { value in
                        onScan(value)
                        dismiss()
                    }
                    .ignoresSafeArea()
                } else {
                    EmptyStateView(
                        title: "Camera unavailable",
                        message: "Camera scanning isn't available here. Paste a shared list instead.",
                        systemImage: AppIcons.qrCode
                    )
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

private struct QRScannerRepresentable: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        context.coordinator.scanner = scanner
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        context.coordinator.startIfNeeded()
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: (String) -> Void
        weak var scanner: DataScannerViewController?
        private var didStart = false

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func startIfNeeded() {
            guard !didStart, let scanner else { return }
            didStart = true
            try? scanner.startScanning()
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            switch item {
            case .barcode(let barcode):
                if let payload = barcode.payloadStringValue {
                    onScan(payload)
                }
            default:
                break
            }
        }
    }
}

#Preview {
    QRScannerScreen { _ in }
}
