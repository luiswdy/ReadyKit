//
//  ItemSummaryFormatter.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/14.
//

struct ItemSummaryFormatter {
    
    static func summaryMessage(
        expiringCount: Int,
        expiredCount: Int) -> String {
            var lines: [String] = []
            if expiredCount > 0 {
                lines.append(String(localized:"‼️ Expired: \(expiredCount) items."))
            }
            if expiringCount > 0 {
                lines.append(String(localized:"⚠️ Nearing Expiration: \(expiringCount) items."))
            }
            if lines.isEmpty {
                return String(localized: "✅ All emergency items are current and in good condition.")
            }
            return lines.joined(separator: "\n")
    }
}
