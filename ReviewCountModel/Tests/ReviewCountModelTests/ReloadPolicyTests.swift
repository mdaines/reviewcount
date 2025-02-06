import Testing
import Foundation
@testable import ReviewCountModel

struct ReloadPolicyTests {
    @Test func initWithoutInfo() async throws {
        let date = Date.now

        #expect(ReloadPolicy(nextReviewsAt: nil, lastActivityAt: nil, since: date) == .regular)
    }

    @Test func initWithNextReviews() async throws {
        let date = Date.now
        let past = date.addingTimeInterval(-60)
        let future = date.addingTimeInterval(60)
        let recent = date.addingTimeInterval(-60)

        #expect(ReloadPolicy(nextReviewsAt: past, lastActivityAt: nil, since: date) == .regular)
        #expect(ReloadPolicy(nextReviewsAt: future, lastActivityAt: nil, since: date) == .nextHour)
        #expect(ReloadPolicy(nextReviewsAt: future, lastActivityAt: recent, since: date) == .nextHour)
    }

    @Test func initWithRecentActivity() async throws {
        let date = Date.now
        let recent = date.addingTimeInterval(-60)
        let notRecent = date.addingTimeInterval(-60 * 10)

        #expect(ReloadPolicy(nextReviewsAt: nil, lastActivityAt: recent, since: date) == .fast)
        #expect(ReloadPolicy(nextReviewsAt: nil, lastActivityAt: notRecent, since: date) == .regular)
    }
}
