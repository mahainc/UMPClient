import Dependencies
import UMPClient
import AnalyticClient
@preconcurrency import UserMessagingPlatform
import UIKit

extension UMPClient: DependencyKey {
    public static var liveValue: Self {
        .init(
            requestConsentIfNeeded: { config in
                @Dependency(\.analyticClient) var analytics

                let parameters = RequestParameters()
                parameters.isTaggedForUnderAgeOfConsent = config.taggedForUnderAgeOfConsent

                applyDebugSettings(config, to: parameters)

                try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)

                let status = ConsentInformation.shared.consentStatus
                let formStatus = ConsentInformation.shared.formStatus
                let formAvailable = formStatus == .available
                #if DEBUG
                print(
                    "🔍 [UMP] post-update consentStatus=\(status.rawValue) formStatus=\(formStatus.rawValue) canRequestAds=\(ConsentInformation.shared.canRequestAds)"
                )
                #endif

                guard formAvailable, status == .required || status == .unknown else {
                    return mapStatus(status)
                }

                let form = try await loadConsentForm()
                try await presentForm(form)

                let finalStatus = ConsentInformation.shared.consentStatus
                #if DEBUG
                print(
                    "🔍 [UMP] post-present consentStatus=\(finalStatus.rawValue) canRequestAds=\(ConsentInformation.shared.canRequestAds)"
                )
                #endif

                if finalStatus == .obtained {
                    await analytics.trackEvent("user_consent", [:])
                    #if DEBUG
                    print("✅ [UMP] User completed consent")
                    #endif
                } else {
                    await analytics.trackEvent("user_not_consent", [:])
                    #if DEBUG
                    print("❌ [UMP] User dismissed or did not complete")
                    #endif
                }
                return mapStatus(finalStatus)
            },
            consentStatus: {
                mapStatus(ConsentInformation.shared.consentStatus)
            },
            canRequestAds: {
                ConsentInformation.shared.canRequestAds
            },
            reset: {
                ConsentInformation.shared.reset()
            }
        )
    }
}

/// Sets `RequestParameters.debugSettings` based on a three-tier waterfall:
///
/// 1. `config.forceConsentFormForQA` → force `.EEA` for every device
///    (production kill-switch, tell the caller to revert before shipping).
/// 2. `config.testDeviceIdentifiers` non-empty → force `.EEA` but only for the
///    listed UUIDs (scalpel, safe to leave committed in dev branches).
/// 3. `#if DEBUG` fallback → force `.EEA` with no test-device list so
///    simulators (which are auto-registered test devices) always see the form.
///
/// In Release with both overrides off, `debugSettings` stays `nil` and UMP uses
/// real IP geography — the correct production path for real users.
private func applyDebugSettings(_ config: UMPClient.Config, to parameters: RequestParameters) {
    if config.forceConsentFormForQA {
        let debugSettings = DebugSettings()
        debugSettings.geography = .EEA
        parameters.debugSettings = debugSettings
        #if DEBUG
        print(
            "🔍 [UMP] forceConsentFormForQA=true; forcing geography=.EEA for ALL devices. Revert before shipping."
        )
        #endif
    } else if !config.testDeviceIdentifiers.isEmpty {
        let debugSettings = DebugSettings()
        debugSettings.geography = .EEA
        debugSettings.testDeviceIdentifiers = config.testDeviceIdentifiers
        parameters.debugSettings = debugSettings
        #if DEBUG
        print(
            "🔍 [UMP] Test-device override active (\(config.testDeviceIdentifiers.count) devices); forcing geography=.EEA."
        )
        #endif
    } else {
        #if DEBUG
        let debugSettings = DebugSettings()
        debugSettings.geography = .EEA
        parameters.debugSettings = debugSettings
        print(
            "🔍 [UMP] DEBUG build: forcing geography=.EEA. Simulators are test devices by default; pass UMPClient.Config(testDeviceIdentifiers: […]) for physical devices."
        )
        #endif
    }
}

/// Maps UMP SDK's `UMPConsentStatus` to our public `UMPClient.ConsentStatus`.
/// Uses the raw ObjC name to avoid the `ConsentStatus` name collision.
private func mapStatus(_ status: UserMessagingPlatform.ConsentStatus) -> UMPClient.ConsentStatus {
    switch status {
    case .notRequired:  return .notRequired
    case .required:     return .required
    case .obtained:     return .obtained
    case .unknown:      fallthrough
    @unknown default:   return .unknown
    }
}

@MainActor
private func loadConsentForm() async throws -> ConsentForm {
    try await withCheckedThrowingContinuation { continuation in
        ConsentForm.load { form, error in
            if let error {
                continuation.resume(throwing: error)
            } else if let form {
                continuation.resume(returning: form)
            } else {
                continuation.resume(
                    throwing: NSError(
                        domain: "UMPClient",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Consent form not available"]
                    )
                )
            }
        }
    }
}

@MainActor
private func presentForm(_ form: ConsentForm) async throws {
    let rootVC = try rootViewController()
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
        form.present(from: rootVC) { error in
            if let error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume()
            }
        }
    }
}

@MainActor
private func rootViewController() throws -> UIViewController {
    guard let scene = UIApplication.shared.connectedScenes.first(where: { $0 is UIWindowScene }) as? UIWindowScene,
          let window = scene.windows.first(where: { $0.isKeyWindow }),
          let rootVC = window.rootViewController else {
        throw NSError(
            domain: "UMPClient",
            code: -2,
            userInfo: [NSLocalizedDescriptionKey: "No root view controller found"]
        )
    }
    return rootVC
}
