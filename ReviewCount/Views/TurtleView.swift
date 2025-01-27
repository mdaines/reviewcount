import SwiftUI
import os

struct TurtleView: View {
    let reviewCountInfo: ReviewCountInfo

    init(reviewCountInfo: ReviewCountInfo) {
        self.reviewCountInfo = reviewCountInfo
    }

    var body: some View {
        HStack {
            Image(systemName: "tortoise.fill")

            switch reviewCountInfo {
            case .none:
                EmptyView()
            case .error:
                Text("!")
            case .reviews(let availableSubjectIds, _):
                Text(availableSubjectIds.count, format: .number)
            }
        }
    }
}
