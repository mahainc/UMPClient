import Dependencies

extension DependencyValues {
    public var umpClient: UMPClient {
        get { self[UMPClient.self] }
        set { self[UMPClient.self] = newValue }
    }
}

extension UMPClient: TestDependencyKey {
    public static var testValue: Self { Self() }
    public static var previewValue: Self { Self() }
}

extension UMPClient {
    /// Always grants consent — useful when testing flows that should run past UMP.
    public static let alwaysObtained: Self = .init(
        requestConsentIfNeeded: { _ in .obtained },
        consentStatus:          { .obtained },
        canRequestAds:          { true },
        reset:                  { }
    )

    /// Simulates "required but not yet answered" — requests never resolve to obtained.
    public static let alwaysRequired: Self = .init(
        requestConsentIfNeeded: { _ in .required },
        consentStatus:          { .required },
        canRequestAds:          { false },
        reset:                  { }
    )
}
