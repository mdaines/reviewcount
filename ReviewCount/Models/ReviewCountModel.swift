import SwiftUI
import Network
import AsyncAlgorithms
import os
import ReviewCountModel

fileprivate let minimumSleepDuration: TimeInterval = 1
fileprivate let fallbackSleepDuration: TimeInterval = 15 * 60

enum ReviewCountInfo {
    case none
    case error(Error)
    case reviews(availableSubjectIds: Set<Int>, nextReviewsAt: Date?)

    init(summaryInfo: SummaryInfo) {
        let ids = summaryInfo.reviews.reduce(into: Set<Int>()) { ids, review in
            if review.availableAt <= Date.now {
                ids.formUnion(review.subjectIds)
            }
        }

        self = .reviews(availableSubjectIds: ids, nextReviewsAt: summaryInfo.nextReviewsAt)
    }

    func hasReviewedSubjects(previous: ReviewCountInfo) -> Bool {
        if case let .reviews(previousIds, _) = previous, case let .reviews(nextIds, _) = self {
            return nextIds.isStrictSubset(of: previousIds)
        } else {
            return false
        }
    }
}

@MainActor
class ReviewCountModel: ObservableObject {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ReviewCountModel")

    @Published private(set) var reviewCountInfo: ReviewCountInfo {
        didSet {
            if reviewCountInfo.hasReviewedSubjects(previous: oldValue) {
                lastActivityAt = .now
            }
        }
    }

    private var lastActivityAt: Date?

    private var reviewCountTask: Task<Void, Error>?

    private var networkPathMonitorTask: Task<Void, Error>?

    init() {
        self.reviewCountInfo = .none

        reload()

        startNetworkPathMonitor()
    }

    func openingStartReviews() {
        self.lastActivityAt = .now

        reload()
    }

    func addAccount(apiToken: String) async throws -> UserInfo {
        let userInfo = try await loadUser(apiToken: apiToken)

        Credentials.set(apiToken)

        reload()

        return userInfo
    }

    func removeAccount() {
        Credentials.remove()

        reload()
    }

    private func startNetworkPathMonitor() {
        networkPathMonitorTask?.cancel()

        self.networkPathMonitorTask = Task {
            let monitor = NWPathMonitor()

            let pathStatusChanged = monitor.adjacentPairs().compactMap { (a, b) in
                if a.status != b.status {
                    return b.status
                } else {
                    return nil
                }
            }

            for await status in pathStatusChanged {
                if status == .satisfied {
                    Self.logger.debug("Network path status became satisfied")

                    reload()
                }
            }
        }
    }

    func reload() {
        reviewCountTask?.cancel()

        reviewCountTask = Task {
            while !Task.isCancelled {
                let (reviewCountInfo, reloadPolicy) = await next()

                if Task.isCancelled {
                    Self.logger.debug("Cancelled, not updating review count info")

                    return
                }

                self.reviewCountInfo = reviewCountInfo

                if reloadPolicy == .none {
                    Self.logger.debug("Not reloading")

                    return
                } else {
                    let nextDate: Date

                    if let maybeNextDate = reloadPolicy.date, maybeNextDate.timeIntervalSinceNow > minimumSleepDuration {
                        nextDate = maybeNextDate
                    } else {
                        nextDate = Date(timeIntervalSinceNow: fallbackSleepDuration)
                    }

                    Self.logger.debug("Reloading at \(nextDate, privacy: .public) (\(nextDate.timeIntervalSinceNow) seconds)")

                    try await Task.sleep(until: .now + .seconds(nextDate.timeIntervalSinceNow))
                }
            }
        }
    }

    private func next() async -> (ReviewCountInfo, ReloadPolicy) {
        guard let apiToken = Credentials.get() else {
            return (.none, .none)
        }

        do {
            let summaryInfo = try await loadSummary(apiToken: apiToken)

            let nextReviewCountInfo = ReviewCountInfo(summaryInfo: summaryInfo)

            if let nextReviewsAt = summaryInfo.nextReviewsAt {
                Self.logger.debug("Next reviews at \(nextReviewsAt) (\(nextReviewsAt.timeIntervalSinceNow) seconds)")
            }

            if let lastActivityAt {
                Self.logger.debug("Last activity at \(lastActivityAt) (\(lastActivityAt.timeIntervalSinceNow) seconds)")
            }

            let reloadPolicy = ReloadPolicy(
                nextReviewsAt: summaryInfo.nextReviewsAt,
                lastActivityAt: lastActivityAt
            )

            return (nextReviewCountInfo, reloadPolicy)
        } catch {
            Self.logger.error("Error checking reviews: \(error.localizedDescription)")

            if error is CancellationError {
                return (.none, .none)
            }

            if let urlError = error as? URLError {
                if urlError.code == .notConnectedToInternet {
                    return (.error(error), .none)
                }
            }

            if let waniKaniError = error as? WaniKaniError {
                if case .unauthorizedError = waniKaniError {
                    return (.error(error), .none)
                }
            }

            return (.error(error), .fallback)
        }
    }
}
