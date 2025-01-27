import SwiftUI

struct ReviewCountStatusView: View {
    let reviewCountInfo: ReviewCountInfo

    var body: some View {
        switch reviewCountInfo {
        case .none:
            EmptyView()
        case .error:
            Text("Error Loading Review Count")

            Divider()
        case .reviews(let availableSubjectIds, let nextReviewsAt):
            if availableSubjectIds.count == 0 {
                if let nextReviewsAt {
                    Text("Next Reviews: \(nextReviewsAt, format: .dateTime)")
                } else {
                    Text("No Reviews Scheduled")
                }
            } else {
                Text("Reviews Available Now")
            }

            Divider()
        }
    }
}
