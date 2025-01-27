import Foundation
import os

fileprivate let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "API")

enum WaniKaniEndpoints {
    static let user = URL(string: "https://api.wanikani.com/v2/user")!
    static let summary = URL(string: "https://api.wanikani.com/v2/summary")!
}

enum WaniKaniError: Error {
    case unexpectedResponseClassError
    case parseError
    case unauthorizedError
    case responseError(code: Int, message: String)
}

func loadWaniKaniEndpoint(url: URL, apiToken: String) async throws -> [String: Any] {
    var request = URLRequest(url: url)
    request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
    request.setValue("20170710", forHTTPHeaderField: "Wanikani-Revision")
    request.cachePolicy = .reloadRevalidatingCacheData

    let (data, response) = try await URLSession.shared.data(for: request)

    let object = try JSONSerialization.jsonObject(with: data)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw WaniKaniError.unexpectedResponseClassError
    }

    guard let objectDictionary = object as? [String: Any] else {
        throw WaniKaniError.parseError
    }

    switch httpResponse.statusCode {
    case 200:
        return objectDictionary

    case 401:
        throw WaniKaniError.unauthorizedError

    default:
        guard let code = objectDictionary["code"] as? Int,
              let message = objectDictionary["error"] as? String else {
            throw WaniKaniError.parseError
        }

        throw WaniKaniError.responseError(code: code, message: message)
    }
}

struct UserInfo {
    let username: String
    let level: Int
}

func loadUser(apiToken: String) async throws -> UserInfo {
    let objectDictionary = try await loadWaniKaniEndpoint(url: WaniKaniEndpoints.user, apiToken: apiToken)

    guard let dataDictionary = objectDictionary["data"] as? [String: Any],
          let username = dataDictionary["username"] as? String,
          let level = dataDictionary["level"] as? Int else {
        throw WaniKaniError.parseError
    }

    return UserInfo(username: username, level: level)
}

struct SummaryInfo {
    struct Review {
        let availableAt: Date
        let subjectIds: [Int]
    }

    let dataUpdatedAt: Date
    let nextReviewsAt: Date?
    let reviews: [Review]
}

func loadSummary(apiToken: String) async throws -> SummaryInfo {
    let objectDictionary = try await loadWaniKaniEndpoint(url: WaniKaniEndpoints.summary, apiToken: apiToken)

    guard let dataDictionary = objectDictionary["data"] as? [String: Any],
          let reviewsArray = dataDictionary["reviews"] as? [Any] else {
        throw WaniKaniError.parseError
    }

    guard let dataUpdatedAt = objectDictionary["data_updated_at"] as? String,
          let dataUpdatedAtDate = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(dataUpdatedAt) else {
        throw WaniKaniError.parseError
    }

    let nextReviewsAtDate: Date?

    if let nextReviewsAt = dataDictionary["next_reviews_at"] as? String {
        guard let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(nextReviewsAt) else {
            throw WaniKaniError.parseError
        }

        nextReviewsAtDate = date
    } else {
        nextReviewsAtDate = nil
    }

    let reviews = try reviewsArray.map { reviewObject in
        guard let reviewDictionary = reviewObject as? [String: Any],
              let availableAt = reviewDictionary["available_at"] as? String,
              let subjectIds = reviewDictionary["subject_ids"] as? [Int],
              let availableAtDate = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(availableAt) else {
            throw WaniKaniError.parseError
        }

        return SummaryInfo.Review(
            availableAt: availableAtDate,
            subjectIds: subjectIds
        )
    }

    return SummaryInfo(
        dataUpdatedAt: dataUpdatedAtDate,
        nextReviewsAt: nextReviewsAtDate,
        reviews: reviews
    )
}
