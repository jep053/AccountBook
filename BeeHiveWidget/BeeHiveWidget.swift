import WidgetKit
import SwiftUI

// 위젯에 표시할 데이터
struct BeeHiveEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let todayTotal: Double
}

// 데이터 로딩
struct BeeHiveProvider: TimelineProvider {
    func placeholder(in context: Context) -> BeeHiveEntry {
        BeeHiveEntry(date: Date(), streak: 3, todayTotal: 25.0)
    }

    func getSnapshot(in context: Context, completion: @escaping (BeeHiveEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BeeHiveEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    func loadEntry() -> BeeHiveEntry {
        let defaults = UserDefaults(suiteName: "group.com.jeongmin.beehive") ?? UserDefaults.standard
        let streak = defaults.integer(forKey: "beehive_streak")
        
        var todayTotal: Double = 0
        if let data = defaults.data(forKey: "beehive_expenses"),
           let expenses = try? JSONDecoder().decode([WidgetExpense].self, from: data) {
            todayTotal = expenses.filter {
                Calendar.current.isDateInToday($0.date)
            }.reduce(0) { $0 + $1.amount }
        }
        return BeeHiveEntry(date: Date(), streak: streak, todayTotal: todayTotal)
    }
}

// 위젯용 간단한 Expense 모델
struct WidgetExpense: Codable {
    let amount: Double
    let date: Date
}

// 꿀 상태
func honeyEmoji(streak: Int) -> String {
    switch streak {
    case 0: return "🫙"
    case 1: return "🍯"
    case 2: return "🍯🐝"
    case 3, 4: return "🍯🐝🐝"
    case 5, 6: return "🍯🐝🐝🐝"
    default: return "🍯✨🐝🐝🐝"
    }
}

// 작은 위젯 (잠금화면용)
struct BeeHiveWidgetSmallView: View {
    let entry: BeeHiveEntry

    var body: some View {
        VStack(spacing: 6) {
            Text(honeyEmoji(streak: entry.streak))
                .font(.system(size: 32))
            Text("\(entry.streak)d streak")
                .font(.caption)
                .fontWeight(.bold)
            Text("$\(entry.todayTotal, specifier: "%.0f") today")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .containerBackground(Color.yellow.opacity(0.15), for: .widget)
    }
}

// 중간 위젯
struct BeeHiveWidgetMediumView: View {
    let entry: BeeHiveEntry

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text(honeyEmoji(streak: entry.streak))
                    .font(.system(size: 40))
                Text("\(entry.streak) day streak")
                    .font(.caption)
                    .fontWeight(.bold)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("$\(entry.todayTotal, specifier: "%.0f")")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Text("🐝 BeeHive")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .containerBackground(Color.yellow.opacity(0.15), for: .widget)
    }
}

// 위젯 설정
struct BeeHiveWidget: Widget {
    let kind: String = "BeeHiveWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BeeHiveProvider()) { entry in
            BeeHiveWidgetSmallView(entry: entry)
        }
        .configurationDisplayName("BeeHive")
        .description("Track your spending streak & today's expenses.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    BeeHiveWidget()
} timeline: {
    BeeHiveEntry(date: .now, streak: 3, todayTotal: 25.0)
}
