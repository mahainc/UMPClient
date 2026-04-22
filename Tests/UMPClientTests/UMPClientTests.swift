import Foundation
import Testing
@testable import UMPClient

@Suite("UMPClient")
struct UMPClientTests {

    @Test("alwaysObtained mock grants consent")
    func alwaysObtained() async throws {
        let client = UMPClient.alwaysObtained
        let status = try await client.requestConsentIfNeeded(UMPConfig())
        #expect(status == .obtained)
        let current = await client.consentStatus()
        #expect(current == .obtained)
        #expect(await client.canRequestAds() == true)
    }

    @Test("alwaysRequired mock blocks consent")
    func alwaysRequired() async throws {
        let client = UMPClient.alwaysRequired
        let status = try await client.requestConsentIfNeeded(UMPConfig())
        #expect(status == .required)
        #expect(await client.canRequestAds() == false)
    }

    @Test("UMPConsentStatus cases cover all expected values")
    func consentStatusCoverage() {
        let cases: [UMPConsentStatus] = [.unknown, .required, .notRequired, .obtained]
        #expect(cases.count == 4)
        #expect(UMPConsentStatus.unknown != UMPConsentStatus.obtained)
    }

    @Test("custom client can return any status")
    func customReturnsAnyStatus() async throws {
        let status: UMPConsentStatus = .notRequired
        let client = UMPClient(
            requestConsentIfNeeded: { _ in status },
            consentStatus: { status },
            canRequestAds: { status == .obtained || status == .notRequired },
            reset: { }
        )
        #expect(try await client.requestConsentIfNeeded(UMPConfig()) == .notRequired)
        #expect(await client.canRequestAds() == true)
    }

    @Test("UMPConfig defaults to production-safe values")
    func configDefaultsAreProductionSafe() {
        let config = UMPConfig()
        #expect(config.forceConsentFormForQA == false)
        #expect(config.testDeviceIdentifiers.isEmpty)
        #expect(config.taggedForUnderAgeOfConsent == false)
    }
}
