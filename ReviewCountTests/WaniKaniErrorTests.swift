import Testing
@testable import ReviewCount

struct WaniKaniErrorTests {
    @Test func localizedDescription() async throws {
        #expect((WaniKaniError.parseError as Error).localizedDescription == "Couldn’t parse the response from the server.")
        #expect((WaniKaniError.unauthorizedError as Error).localizedDescription == "Invalid API token.")
        #expect((WaniKaniError.responseError(code: 404, message: "Not Found") as Error).localizedDescription == "The server returned an error response.")
        #expect((WaniKaniError.unexpectedResponseClassError as Error).localizedDescription == "The server returned an error response.")
    }
}
