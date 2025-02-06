import Foundation

public enum WaniKaniError: Error {
    case unexpectedResponseClassError
    case parseError
    case unauthorizedError
    case responseError(code: Int, message: String)
}

extension WaniKaniError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unexpectedResponseClassError, .responseError:
            return "The server returned an error response."

        case .unauthorizedError:
            return "Invalid API token."

        case .parseError:
            return "Couldn’t parse the response from the server."
        }
    }
}
