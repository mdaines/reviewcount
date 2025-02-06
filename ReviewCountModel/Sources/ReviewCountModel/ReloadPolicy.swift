import Foundation

fileprivate let minimumSleepDuration: TimeInterval = 1
fileprivate let fastSleepDuration: TimeInterval = 15
fileprivate let regularSleepDuration: TimeInterval = 5 * 60
fileprivate let fallbackSleepDuration: TimeInterval = 15 * 60
fileprivate let recentActivityDuration: TimeInterval = 5 * 60

public enum ReloadPolicy: Equatable {
    case none
    case nextHour
    case regular
    case fast
    case fallback

    public var date: Date? {
        return date()
    }

    public init(nextReviewsAt: Date?, lastActivityAt: Date?, since date: Date = .now) {
        if let nextReviewsAt = nextReviewsAt, nextReviewsAt > date {
            self = .nextHour
        } else if let lastActivityAt, lastActivityAt.timeIntervalSince(date) > -recentActivityDuration {
            self = .fast
        } else {
            self = .regular
        }
    }

    public func date(since date: Date = .now, calendar: Calendar = .current) -> Date? {
        switch self {
        case .none:
            return nil

        case .nextHour:
            return calendar.nextDate(after: date.addingTimeInterval(minimumSleepDuration), matching: DateComponents(minute: 0), matchingPolicy: .nextTime)

        case .regular:
            return date.addingTimeInterval(regularSleepDuration)

        case .fast:
            return date.addingTimeInterval(fastSleepDuration)

        case .fallback:
            return date.addingTimeInterval(fallbackSleepDuration)
        }
    }
}
