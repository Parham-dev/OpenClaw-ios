import Foundation

struct OutreachStats: Decodable, Sendable {
    let totalLeads: Int
    let newLeads: Int
    let emailSent: Int
    let waSent: Int
    let replied: Int
    let converted: Int
    let replyRatePct: Double
    let timestamp: Int
}
