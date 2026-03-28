import SwiftUI

struct StatsView: View {
    @ObservedObject var store: BeeHiveStore
    @State private var showingDatePicker = false
    @StateObject private var recurringStore = RecurringStore()
    @State private var showingRecurring = false
    @State private var startDate: Date = Calendar.current.date(from: DateComponents(year: Calendar.current.component(.year, from: Date()), month: Calendar.current.component(.month, from: Date()), day: 1))!
    @State private var endDate: Date = Date()
    
    var filteredExpenses: [Expense] {
        store.expenses.filter { $0.date >= startDate && $0.date <= endDate }
    }
    
    var categoryTotals: [(category: ExpenseCategory, total: Double)] {
        let grouped = Dictionary(grouping: filteredExpenses, by: { $0.category })
        return ExpenseCategory.allCases.compactMap { category in
            let total = grouped[category]?.reduce(0) { $0 + $1.amount } ?? 0
            if total > 0 { return (category: category, total: total) }
            return nil
        }.sorted { $0.total > $1.total }
    }
    
    var totalSpending: Double { filteredExpenses.reduce(0) { $0 + $1.amount } }
    
    var dateRangeLabel: String {
        let formatter = DateFormatter()
        let language = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
            formatter.locale = Locale(identifier: language == "ko" ? "ko_KR" : "en_US")
        formatter.dateFormat = "MMM yyyy"
        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)
        if start == end { return start }
        return "\(start) - \(end)"
    }
    
    var body: some View {
        // ✅ Fix: NavigationStack → NavigationView
        // 다른 탭들은 모두 NavigationView를 사용하는데 여기만 NavigationStack이었음
        // Navigation 타입 혼용 시 탭 전환 충돌 발생 → 통일
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 0) {
                        VStack(spacing: 8) {
                            Button(action: { showingDatePicker = true }) {
                                HStack(spacing: 4) {
                                    Text(dateRangeLabel)
                                        .font(.subheadline)
                                        .foregroundColor(.black.opacity(0.9))
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.black.opacity(0.9))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(20)
                            }
                            Text(L("stats.spending"))
                                .font(.subheadline)
                                .foregroundColor(.black.opacity(0.8))
                            Text(formatCurrency(totalSpending))
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        
                        Rectangle()
                            .fill(Color.black.opacity(0.2))
                            .frame(width: 1, height: 80)
                        
                        Button(action: { showingRecurring = true }) {
                            VStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Text(L("stats.fixed"))
                                        .font(.subheadline)
                                        .foregroundColor(.black.opacity(0.9))
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.black.opacity(0.9))
                                }
                                Text(formatCurrency(recurringStore.monthlyTotal))
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.black)
                                Text(L("stats.perMonth"))
                                    .font(.caption)
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        }
                    }
                    .background(Color.yellow.opacity(0.8))
                    .cornerRadius(20)
                    .sheet(isPresented: $showingRecurring) {
                        RecurringView(store: recurringStore)
                    }
                    
                    if categoryTotals.isEmpty {
                        VStack(spacing: 12) {
                            Text("🐝").font(.system(size: 40))
                            Text(L("stats.empty")).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(L("stats.byCategory")).font(.headline)
                            ForEach(categoryTotals, id: \.category) { item in
                                CategoryBarRow(category: item.category, total: item.total, totalSpending: totalSpending)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                    }
                    
                    if !filteredExpenses.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L("stats.transactions")).font(.headline)
                            ForEach(filteredExpenses.reversed()) { expense in
                                HStack {
                                    Text(expense.category.icon)
                                        .font(.title3)
                                        .frame(width: 36, height: 36)
                                        .background(expense.category.color.opacity(0.15))
                                        .cornerRadius(10)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(expense.category.localizedName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        if !expense.note.isEmpty {
                                            Text(expense.note).font(.caption).foregroundColor(.secondary)
                                        }
                                        Text(expense.date, style: .date).font(.caption2).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("-\(formatCurrency(expense.amount))")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.red)
                                }
                                Divider()
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                    }
                }
                .padding()
            }
            .navigationTitle(L("stats.title"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingDatePicker) {
                DateRangePickerView(
                    startDate: $startDate,
                    endDate: $endDate,
                    minDate: store.expenses.map { $0.date }.min() ?? Date()
                )
            }
        }
        .refreshOnLanguageChange()
    }
}

// MARK: - Date Range Picker
struct DateRangePickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Environment(\.dismiss) var dismiss
    @State private var tempStart: Date
    @State private var tempEnd: Date
    let minDate: Date
    
    init(startDate: Binding<Date>, endDate: Binding<Date>, minDate: Date) {
        _startDate = startDate
        _endDate = endDate
        _tempStart = State(initialValue: startDate.wrappedValue)
        _tempEnd = State(initialValue: endDate.wrappedValue)
        self.minDate = minDate
    }
    
    var quickOptions: [(label: String, start: Date, end: Date)] {
        let now = Date()
        let calendar = Calendar.current
        let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)!
        let lastMonthEnd = calendar.date(byAdding: .day, value: -1, to: thisMonthStart)!
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: thisMonthStart)!
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: thisMonthStart)!
        let thisYearStart = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: 1, day: 1))!
        return [
            (L("datePicker.thisMonth"), thisMonthStart, now),
            (L("datePicker.lastMonth"), lastMonthStart, lastMonthEnd),
            (L("datePicker.last3Months"), threeMonthsAgo, now),
            (L("datePicker.last6Months"), sixMonthsAgo, now),
            (L("datePicker.thisYear"), thisYearStart, now),
        ]
    }
    
    var body: some View {
        // ✅ Fix: NavigationStack → NavigationView (sheet 내부도 통일)
        NavigationView {
            Form {
                Section(L("datePicker.quickSelect")) {
                    ForEach(quickOptions, id: \.label) { option in
                        Button(action: { tempStart = option.start; tempEnd = option.end }) {
                            HStack {
                                Text(option.label).foregroundColor(.primary)
                                Spacer()
                                if Calendar.current.isDate(tempStart, inSameDayAs: option.start) &&
                                   Calendar.current.isDate(tempEnd, inSameDayAs: option.end) {
                                    Image(systemName: "checkmark").foregroundColor(.yellow)
                                }
                            }
                        }
                    }
                }
                Section(L("datePicker.customRange")) {
                    DatePicker(L("datePicker.start"), selection: $tempStart, in: minDate..., displayedComponents: [.date])
                    DatePicker(L("datePicker.end"), selection: $tempEnd, in: tempStart..., displayedComponents: [.date])
                }
            }
            .navigationTitle(L("datePicker.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("datePicker.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("datePicker.apply")) {
                        startDate = tempStart
                        endDate = tempEnd
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                }
            }
        }
    }
}

// MARK: - Category Bar Row
struct CategoryBarRow: View {
    let category: ExpenseCategory
    let total: Double
    let totalSpending: Double
    
    var percentage: Double { totalSpending > 0 ? total / totalSpending : 0 }
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(category.icon)
                Text(category.localizedName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(percentage * 100))%").font(.caption).foregroundColor(.secondary)
                Text(formatCurrency(total)).font(.subheadline).fontWeight(.semibold)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(Color(.systemGray5)).frame(height: 10)
                    RoundedRectangle(cornerRadius: 6).fill(category.color)
                        .frame(width: geo.size.width * percentage, height: 10)
                }
            }
            .frame(height: 10)
        }
    }
}

#Preview {
    StatsView(store: BeeHiveStore())
}
