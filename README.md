# UMPClient

> **Archived — end of life.** The UMP consent flow lives in
> [ConsentClient](https://github.com/mahainc/ConsentClient) 2.0.0 and later, which owns
> App Tracking Transparency and the UMP form together and conforms
> `FunnelClient.Consent.Providing` directly. The two were always sequenced as one
> decision (ATT first, then UMP), so splitting them across packages meant every host
> re-implemented the ordering. Nothing here was dropped: the three-tier geography
> waterfall, the `formAvailable && (required || unknown)` presentation guard, and the
> `user_consent` / `user_not_consent` analytics tagging all moved across. No further
> releases will be made.
>
> Migration — replace `@Dependency(\.umpClient)` with `@Dependency(\.consentClient)`:
>
> | UMPClient | ConsentClient |
> |---|---|
> | `requestConsentIfNeeded(config)` | `requestAdsConsent(config)` — returns the `ConsentStatus` |
> | `canRequestAds()` | `canRequestAds()` |
> | `reset()` | `resetAdsConsent()` |
> | `UMPClient.Config` | `ConsentClient.Config` (a real type, no longer a typealias) |

A TCA-style dependency client wrapping Google's User Messaging Platform (UMP) SDK for GDPR / EEA consent collection. Presents the consent form when required, surfaces the resulting `ConsentStatus`, and exposes a debug-only QA escape hatch for testing the EEA flow from non-EEA test devices.

## Layout

- **`UMPClient`** — interface: `requestConsentIfNeeded(_:)`, `consentStatus()`, `canRequestAds()`, `reset()`, plus a `Config` value type with the QA-override knobs and a `ConsentStatus` enum.
- **`UMPClientLive`** — `GoogleUserMessagingPlatform` wrapper that also tags events through `AnalyticsClient`.

## Installation

```swift
.package(url: "https://github.com/mahainc/UMPClient.git", from: "1.0.1"),
```

`UMPClient` on feature targets; `UMPClientLive` on the app target.

## Usage

```swift
import UMPClient
import ComposableArchitecture

@Reducer
struct AppFeature {
    enum Action {
        case onAppear
        case consentResolved(UMPClient.ConsentStatus)
    }

    @Dependency(\.umpClient) var ump

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let status = try await ump.requestConsentIfNeeded(.init())
                    await send(.consentResolved(status))
                }

            case .consentResolved(.obtained), .consentResolved(.notRequired):
                // Safe to start ads + analytics SDKs that depend on consent.
                return .none

            case .consentResolved:
                return .none
            }
        }
    }
}
```

## QA: testing the consent form from a non-EEA device

The `Config` type exposes two QA-override knobs that work in *both* Debug and Release builds, so you can drive the UMP form on a TestFlight / Ad Hoc build from outside the EEA:

```swift
// Hammer — force every device to see the form. MUST be false before App Store submission.
try await ump.requestConsentIfNeeded(.init(forceConsentFormForQA: true))

// Scalpel — only listed UMP test-device UUIDs see the form.
// The UUID is what the UMP SDK prints to the Xcode console on first run.
try await ump.requestConsentIfNeeded(
    .init(testDeviceIdentifiers: ["EA7583CD-A667-48BC-B806-42ECB2B48606"])
)
```

In Debug builds, the live implementation additionally forces `.EEA` geography when neither override is set — so the simulator always sees the consent form.

## COPPA / children's apps

```swift
try await ump.requestConsentIfNeeded(.init(taggedForUnderAgeOfConsent: true))
```

## Testing

`@DependencyClient` generates unimplemented `testValue` defaults; the package ships convenience mocks too:

```swift
let store = TestStore(initialState: AppFeature.State()) {
    AppFeature()
} withDependencies: {
    $0.umpClient = .alwaysObtained   // or .alwaysRequired
}
```

## Dependencies

- `swift-dependencies` from 1.9.0
- `swift-case-paths` from 1.5.0
- `swift-package-manager-google-user-messaging-platform` (GoogleUserMessagingPlatform) from 3.0.0
- `AnalyticsClient` from 1.0.1

## Platform support

- iOS 16+

## License

MIT — see [LICENSE](./LICENSE).
