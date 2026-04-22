import DependenciesMacros

public enum UMPConsentStatus: Sendable, Equatable {
    case unknown
    case required
    case notRequired
    case obtained
}

/// Per-call configuration for `UMPClient.requestConsentIfNeeded(_:)`.
///
/// All fields default to production-safe values (`UMPConfig()` is safe to ship).
/// The QA-override fields (`forceConsentFormForQA`, `testDeviceIdentifiers`)
/// take effect in *both* Debug and Release builds so you can drive the UMP form
/// on a TestFlight / Ad Hoc Release build from a non-EEA country. In Debug
/// builds the live implementation additionally forces `.EEA` geography when
/// neither override is set, so the simulator always sees the consent form.
public struct UMPConfig: Sendable, Equatable {
    /// Hammer: force `DebugSettings.geography = .EEA` for every device and every
    /// build configuration, bypassing UMP's real IP geography check. **MUST be
    /// `false` before any App Store submission** — a `true` value tells Google's
    /// UMP backend every user is in the EEA, which AdMob will reject for
    /// non-registered real devices.
    public let forceConsentFormForQA: Bool

    /// Scalpel: registered UMP test-device UUIDs that should see `.EEA` in any
    /// build configuration. The identifier is the UUID the UMP SDK prints to
    /// the Xcode console on first run — search the log for
    /// `<UMP SDK>To enable debug mode for this device, set: UMPDebugSettings.testDeviceIdentifiers = @[ @"…" ]`.
    /// Harmless to leave populated in shipped builds (only the listed devices
    /// are overridden), but as a hygiene rule prefer clearing before release.
    public let testDeviceIdentifiers: [String]

    /// Passed through to `RequestParameters.isTaggedForUnderAgeOfConsent`. Set
    /// to `true` if your app is directed to children — Google will then serve
    /// only COPPA-compliant ads.
    public let taggedForUnderAgeOfConsent: Bool

    public init(
        forceConsentFormForQA: Bool = false,
        testDeviceIdentifiers: [String] = [],
        taggedForUnderAgeOfConsent: Bool = false
    ) {
        self.forceConsentFormForQA = forceConsentFormForQA
        self.testDeviceIdentifiers = testDeviceIdentifiers
        self.taggedForUnderAgeOfConsent = taggedForUnderAgeOfConsent
    }
}

@DependencyClient
public struct UMPClient: Sendable {
    /// Requests consent-info update, loads the consent form if available, and presents it.
    /// Returns the final `ConsentStatus` after the user interacts (or `.notRequired` if no form was needed).
    public var requestConsentIfNeeded: @Sendable (UMPConfig) async throws -> UMPConsentStatus
    public var consentStatus:          @Sendable () async -> UMPConsentStatus = { .unknown }
    public var canRequestAds:          @Sendable () async -> Bool = { false }
    /// Clears cached consent state (useful in debug / test builds).
    public var reset:                  @Sendable () async -> Void
}
