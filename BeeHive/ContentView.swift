import SwiftUI
import Combine
import WidgetKit
import UserNotifications
 
// MARK: - Data Models
struct Expense: Identifiable, Codable {
    let id: UUID
    var amount: Double
    var category: ExpenseCategory
    var note: String
    var date: Date
    
    init(id: UUID = UUID(), amount: Double, category: ExpenseCategory, note: String = "", date: Date = Date()) {
        self.id = id
        self.amount = amount
        self.category = category
        self.note = note
        self.date = date
    }
}
 
enum ExpenseCategory: String, CaseIterable, Codable {
    case eat = "Eat"
    case live = "Live"
    case wear = "Wear"
    case enjoy = "Enjoy"
    case edu = "Edu"
    case ride = "Ride"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .eat: return "🍔"
        case .live: return "🏠"
        case .wear: return "👕"
        case .enjoy: return "🎉"
        case .edu: return "📚"
        case .ride: return "🚗"
        case .other: return "📦"
        }
    }
    
    var color: Color {
        switch self {
        case .eat: return .orange
        case .live: return .blue
        case .wear: return .purple
        case .enjoy: return .green
        case .edu: return .red
        case .ride: return .cyan
        case .other: return .gray
        }
    }
    
    // ✅ Fix: NSLocalizedString → L() 로 교체
    // NSLocalizedString은 기기 언어만 따르므로 앱 내 언어 설정이 무시됨
    var localizedName: String {
        switch self {
        case .eat:   return L("category.eat")
        case .live:  return L("category.live")
        case .wear:  return L("category.wear")
        case .enjoy: return L("category.enjoy")
        case .edu:   return L("category.edu")
        case .ride:  return L("category.ride")
        case .other: return L("category.other")
        }
    }
}
 
// MARK: - Storage
class BeeHiveStore: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var streak: Int = 0
    @Published var lastLoggedDate: Date? = nil
    
    private let expensesKey = "beehive_expenses"
    private let streakKey = "beehive_streak"
    private let lastLoggedKey = "beehive_lastlogged"
    
    init() {
        load()
        updateStreak()
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted { self.scheduleEveningReminder() }
        }
    }
 
    func scheduleEveningReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["beehive_evening"])
        let content = UNMutableNotificationContent()
        content.title = "🐝 BeeHive"
        content.body = L("settings.notification.body")
        content.sound = .default
        var dateComponents = DateComponents()
        dateComponents.hour = 21
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "beehive_evening", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    var honeyStatus: String {
        switch streak {
        case 0: return "🫙"
        case 1: return "🍯"
        case 2: return "🍯🐝"
        case 3, 4: return "🍯🐝🐝"
        case 5, 6: return "🍯🐝🐝🐝"
        default: return "🍯✨🐝🐝🐝"
        }
    }
    
    var honeyMessage: String {
        switch streak {
        case 0: return L("streak.message.0")
        case 1: return L("streak.message.1")
        case 2: return L("streak.message.2")
        case 3, 4: return L("streak.message.3")
        case 5, 6: return L("streak.message.5")
        default: return L("streak.message.7")
        }
    }
    
    func addExpense(_ expense: Expense) {
        expenses.append(expense)
        lastLoggedDate = Date()
        updateStreak()
        save()
    }
    
    func deleteExpense(at offsets: IndexSet) {
        expenses.remove(atOffsets: offsets)
        save()
    }
    
    func updateStreak() {
        guard let last = lastLoggedDate else { streak = 0; return }
        let daysSince = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        if daysSince >= 3 {
            streak = 0
        } else if Calendar.current.isDateInToday(last) {
            // 오늘 기록했으면 streak 유지
        } else {
            streak = max(0, streak)
        }
    }
    
    func incrementStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        if let last = lastLoggedDate {
            let lastDay = Calendar.current.startOfDay(for: last)
            if lastDay != today { streak += 1 }
        } else {
            streak = 1
        }
    }
    
    var todayExpenses: [Expense] {
        expenses.filter { Calendar.current.isDateInToday($0.date) }
    }
    
    var todayTotal: Double {
        todayExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var monthlyTotal: Double {
        let now = Date()
        let month = Calendar.current.component(.month, from: now)
        let year = Calendar.current.component(.year, from: now)
        return expenses.filter {
            Calendar.current.component(.month, from: $0.date) == month &&
            Calendar.current.component(.year, from: $0.date) == year
        }.reduce(0) { $0 + $1.amount }
    }
    
    var sortedCategories: [ExpenseCategory] {
        let counts = Dictionary(grouping: expenses, by: { $0.category }).mapValues { $0.count }
        return ExpenseCategory.allCases.sorted { (counts[$0] ?? 0) > (counts[$1] ?? 0) }
    }
    
    private var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: "group.com.jeongmin.beehive") ?? UserDefaults.standard
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(expenses) {
            sharedDefaults.set(encoded, forKey: expensesKey)
        }
        sharedDefaults.set(streak, forKey: streakKey)
        sharedDefaults.set(lastLoggedDate, forKey: lastLoggedKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func load() {
        if let data = sharedDefaults.data(forKey: expensesKey),
           let decoded = try? JSONDecoder().decode([Expense].self, from: data) {
            expenses = decoded
        }
        streak = sharedDefaults.integer(forKey: streakKey)
        lastLoggedDate = sharedDefaults.object(forKey: lastLoggedKey) as? Date
    }
}
 
// MARK: - Main View
struct ContentView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @StateObject private var store = BeeHiveStore()
    @State private var showingAddExpense = false
    @State private var showingSimulator = false
    
    var body: some View {
        // ✅ Fix: .refreshOnLanguageChange() 제거
        // TabView에 .id()가 붙으면 언어 변경 시 TabView 전체가 재생성되어
        // 탭 인덱스가 0(홈)으로 리셋되는 버그 발생 → 각 탭 내부에서 처리
        TabView {
            // 홈 탭
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        HoneyStreakCard(store: store)
                        SummaryCard(store: store)
                        TodayExpensesList(store: store)
                        
                        Button(action: { showingSimulator = true }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(L("home.simulator.button.title"))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Text(L("home.simulator.button.subtitle"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.yellow.opacity(0.15))
                            .cornerRadius(16)
                        }
                        .sheet(isPresented: $showingSimulator) {
                            NavigationView {
                                SimulatorView()
                                    .toolbar {
                                        ToolbarItem(placement: .navigationBarTrailing) {
                                            Button(L("common.done")) { showingSimulator = false }
                                        }
                                    }
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("🐝 BeeHive")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddExpense = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.yellow)
                        }
                    }
                }
                .sheet(isPresented: $showingAddExpense) {
                    AddExpenseView(store: store)
                }
                .onAppear {
                    store.requestNotificationPermission()
                }
            }
            .refreshOnLanguageChange() // ✅ 각 탭에 개별 적용
            .tabItem {
                Image(systemName: "house.fill")
                Text(L("tab.home"))
            }
            
            StatsView(store: store)
                .refreshOnLanguageChange() // ✅ 각 탭에 개별 적용
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text(L("tab.spending"))
                }
            
            AssetsView()
                .refreshOnLanguageChange() // ✅ 각 탭에 개별 적용
                .tabItem {
                    Image(systemName: "chart.pie.fill")
                    Text(L("tab.assets"))
                }
            
            SettingsView()
                .refreshOnLanguageChange() // ✅ 각 탭에 개별 적용
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text(L("tab.settings"))
                }
        }
        .accentColor(.yellow)
    }
}
 
// MARK: - Honey Streak Card
struct HoneyStreakCard: View {
    @ObservedObject var store: BeeHiveStore
    
    var body: some View {
        VStack(spacing: 12) {
            Text(store.honeyStatus)
                .font(.system(size: 60))
            Text(String(format: L("streak.days"), store.streak))
                .font(.title2)
                .fontWeight(.bold)
            Text(store.honeyMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.yellow.opacity(0.15))
        .cornerRadius(20)
    }
}
 
// MARK: - Summary Card
struct SummaryCard: View {
    @ObservedObject var store: BeeHiveStore
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 6) {
                Text(L("summary.today"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatCurrency(store.todayTotal))
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            
            Divider().frame(height: 40)
            
            VStack(spacing: 6) {
                Text(L("summary.thisMonth"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatCurrency(store.monthlyTotal))
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
 
// MARK: - Today Expenses List
struct TodayExpensesList: View {
    @ObservedObject var store: BeeHiveStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("home.todayExpenses"))
                .font(.headline)
            
            if store.todayExpenses.isEmpty {
                VStack(spacing: 8) {
                    Text("🐝")
                        .font(.system(size: 36))
                    Text(L("home.todayExpenses.empty"))
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(store.todayExpenses.reversed()) { expense in
                    HStack {
                        Text(expense.category.icon)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(expense.category.color.opacity(0.15))
                            .cornerRadius(12)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(expense.category.localizedName)
                                .fontWeight(.medium)
                            if !expense.note.isEmpty {
                                Text(expense.note)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Text("-\(formatCurrency(expense.amount))")
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
 
// MARK: - Add Expense View
struct AddExpenseView: View {
    @ObservedObject var store: BeeHiveStore
    @Environment(\.dismiss) var dismiss
    
    @State private var amount = ""
    @State private var note = ""
    @State private var selectedCategory: ExpenseCategory = .eat
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text(L("addExpense.howMuch"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(UserDefaults.standard.string(forKey: "appLanguage") == "ko" ? "₩" : "$")
                            .font(.title)
                            .foregroundColor(.secondary)
                        Text(amount.isEmpty ? "0" : amount)
                            .font(.system(size: 56, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(Color.yellow.opacity(0.1))
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(store.sortedCategories, id: \.self) { category in
                            VStack(spacing: 6) {
                                Text(category.icon)
                                    .font(.title2)
                                    .frame(width: 52, height: 52)
                                    .background(selectedCategory == category ? category.color.opacity(0.3) : Color(.systemGray6))
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(selectedCategory == category ? category.color : Color.clear, lineWidth: 2)
                                    )
                                Text(category.localizedName)
                                    .font(.caption2)
                                    .foregroundColor(selectedCategory == category ? category.color : .secondary)
                            }
                            .onTapGesture { selectedCategory = category }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 16)
                
                TextField(L("addExpense.note.placeholder"), text: $note)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                
                NumpadView(amount: $amount)
                    .padding(.top, 16)
                
                Spacer()
            }
            .navigationTitle(L("addExpense.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("common.save")) { saveExpense() }
                        .fontWeight(.bold)
                        .disabled(amount.isEmpty || amount == "0")
                }
            }
        }
    }
    
    func saveExpense() {
        guard let amountDouble = Double(amount), amountDouble > 0 else { return }
        store.incrementStreak()
        store.addExpense(Expense(amount: amountDouble, category: selectedCategory, note: note))
        dismiss()
    }
}
 
// MARK: - Custom Numpad
struct NumpadView: View {
    @Binding var amount: String
    
    let buttons: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"]
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { btn in
                        Button(action: { handleTap(btn) }) {
                            Text(btn)
                                .font(.title2)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    func handleTap(_ btn: String) {
        if btn == "⌫" {
            if !amount.isEmpty { amount.removeLast() }
        } else if btn == "." {
            if !amount.contains(".") { amount += "." }
        } else {
            if amount == "0" { amount = btn }
            else { amount += btn }
        }
    }
}
 
#Preview {
    ContentView()
}
