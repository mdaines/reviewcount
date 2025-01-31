import SwiftUI
import Network
import AsyncAlgorithms
import os

fileprivate let minimumSleepDuration: TimeInterval = 1
fileprivate let fastSleepDuration: TimeInterval = 15
fileprivate let regularSleepDuration: TimeInterval = 5 * 60
fileprivate let fallbackSleepDuration: TimeInterval = 15 * 60
fileprivate let recentActivityDuration: TimeInterval = 5 * 60

enum ReviewCountInfo: Equatable {
    case none
    case error
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

enum ReloadPolicy: Equatable {
    case none
    case nextHour
    case regular
    case fast
    case fallback

    var date: Date? {
        switch self {
        case .none:
            return nil

        case .nextHour:
            return Calendar.current.nextDate(after: .now.addingTimeInterval(minimumSleepDuration), matching: DateComponents(minute: 0), matchingPolicy: .nextTime)

        case .regular:
            return Date(timeIntervalSinceNow: regularSleepDuration)

        case .fast:
            return Date(timeIntervalSinceNow: fastSleepDuration)

        case .fallback:
            return Date(timeIntervalSinceNow: fallbackSleepDuration)
        }
    }
}

@MainActor
class ReviewCountModel: ObservableObject {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ReviewCountModel")

    @Published private(set) var reviewCountInfo: ReviewCountInfo {
        didSet {
            if reviewCountInfo.hasReviewedSubjects(previous: oldValue) {
                lastReviewedSubjectsAt = .now
            }
        }
    }

    private var lastStartReviewsAt: Date?

    private var lastReviewedSubjectsAt: Date?

    private var reviewCountTask: Task<Void, Error>?

    private var networkPathMonitorTask: Task<Void, Error>?

    init() {
        self.reviewCountInfo = .none

        reload()

        startNetworkPathMonitor()
    }

    func openingStartReviews() {
        self.lastStartReviewsAt = .now

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

    private func reload() {
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

            if let lastStartReviewsAt {
                Self.logger.debug("Last opened start reviews at \(lastStartReviewsAt) (\(lastStartReviewsAt.timeIntervalSinceNow) seconds)")
            }

            if let lastReviewedSubjectsAt {
                Self.logger.debug("Last reviewed subjects at \(lastReviewedSubjectsAt) (\(lastReviewedSubjectsAt.timeIntervalSinceNow) seconds)")
            }

            if let nextReviewsAt = summaryInfo.nextReviewsAt, nextReviewsAt > .now {
                Self.logger.debug("Next reviews are in the future: reloading next hour")

                return (nextReviewCountInfo, .nextHour)
            } else if let lastStartReviewsAt, lastStartReviewsAt.timeIntervalSinceNow > -recentActivityDuration {
                Self.logger.debug("Recently opened start reviews: reloading at higher frequency")

                return (nextReviewCountInfo, .fast)
            } else if let lastReviewedSubjectsAt, lastReviewedSubjectsAt.timeIntervalSinceNow > -recentActivityDuration {
                Self.logger.debug("Recently reviewed subjects: reloading at higher frequency")

                return (nextReviewCountInfo, .fast)
            } else {
                return (nextReviewCountInfo, .regular)
            }
        } catch {
            Self.logger.error("Error checking reviews: \(error.localizedDescription)")

            if error is CancellationError {
                return (.none, .none)
            }

            if let urlError = error as? URLError {
                if urlError.code == .notConnectedToInternet {
                    return (.error, .none)
                }
            }

            if let waniKaniError = error as? WaniKaniError {
                if case .unauthorizedError = waniKaniError {
                    return (.error, .none)
                }
            }

            return (.error, .fallback)
        }
    }
}
