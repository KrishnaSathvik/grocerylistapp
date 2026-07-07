import AVFoundation
import SwiftUI
import UIKit
import VisionKit

struct QRScannerScreen: View {
    @Environment(\.dismiss) private var dismiss
    let onScan: (String) -> Void

    @State private var state: QRScannerLoadState = .loading

    private enum QRScannerLoadState: Equatable {
        case loading
        case ready
        case permissionDenied
        case unavailable(String)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch state {
                case .loading:
                    ProgressView("Preparing camera…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .ready:
                    QRScannerRepresentable { value in
                        onScan(value)
                        dismiss()
                    }
                    .ignoresSafeArea()
                case .permissionDenied:
                    scannerUnavailableView(
                        title: "Camera access needed",
                        message: "Allow camera access in Settings to scan QR codes, or paste a share link instead."
                    ) {
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                case .unavailable(let message):
                    scannerUnavailableView(
                        title: "Camera unavailable",
                        message: message
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
            .task {
                await prepareScanner()
            }
        }
    }

    @ViewBuilder
    private func scannerUnavailableView<Actions: View>(
        title: String,
        message: String,
        @ViewBuilder actions: () -> Actions = { EmptyView() }
    ) -> some View {
        VStack(spacing: 16) {
            EmptyStateView(
                title: title,
                message: message,
                systemImage: AppIcons.qrCode
            )
            actions()
                .adaptiveScreenContent()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func prepareScanner() async {
        guard DataScannerViewController.isSupported else {
            state = .unavailable("QR scanning isn't supported on this device. Paste a share link instead.")
            return
        }

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            break
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else {
                state = .permissionDenied
                return
            }
        case .denied, .restricted:
            state = .permissionDenied
            return
        @unknown default:
            state = .permissionDenied
            return
        }

        if DataScannerViewController.isAvailable {
            state = .ready
        } else {
            state = .unavailable("Camera scanning isn't available here. Paste a share link instead.")
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
