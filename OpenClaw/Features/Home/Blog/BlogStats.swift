import Foundation

struct BlogPipelineItem: Sendable {
    let label: String
    let count: Int
}

struct BlogStats: Decodable, Sendable {
    let published: Int
    let queued: Int
    let researching: Int
    let writing: Int
    let generatingImages: Int
    let publishing: Int
    let lastPublishedTitle: String?
    let lastPublishedSlug: String?
    let lastPublishedUrl: String?
    let timestamp: Int

    /// Non-zero pipeline stages for pill display.
    var activePipeline: [BlogPipelineItem] {
        [
            BlogPipelineItem(label: "Queued",      count: queued),
            BlogPipelineItem(label: "Researching", count: researching),
            BlogPipelineItem(label: "Writing",     count: writing),
            BlogPipelineItem(label: "Images",      count: generatingImages),
            BlogPipelineItem(label: "Publishing",  count: publishing),
        ].filter { $0.count > 0 }
    }
}
