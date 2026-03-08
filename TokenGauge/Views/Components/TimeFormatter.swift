import Foundation

enum TimeFormatter {
    /// 상대 시간: "1시간 59분"
    static func format(_ interval: TimeInterval) -> String {
        guard interval > 0 else { return "곧 리셋" }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        } else {
            return "\(minutes)분"
        }
    }

    /// 메뉴바용 축약: "2h30m"
    static func shortFormat(_ interval: TimeInterval) -> String {
        guard interval > 0 else { return "0m" }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h\(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// 리셋 날짜 포맷: "(금) 오후 3:00에 재설정"
    static func resetDateFormat(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "(E) a h:mm"
        return "\(formatter.string(from: date))에 재설정"
    }
}
