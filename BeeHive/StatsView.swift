import SwiftUI

struct StatsView: View {
    @ObservedObject var store: BeeHiveStore
    @State private var showingDatePicker = false
    @StateObject private var recurringStore = RecurringStore()
    @State private var showingRecurring = false
    @State private var startDate: Date = Calendar.current.date(from: DateComponents(year: Calendar.current.component(.year, from: Date()), month: Calendar.current.component(.month, from: Date()), day: 1))!
    @State private var endDate: Date = Date()
    
    var filteredExpenses: [Expense] {
        store.expenses.filter {
            $0.date >= startDate && $0.date <= endDate
        }
    }
    
    var categoryTotals: [(category: ExpenseCategory, total: Double)] {
        let grouped = Dictionary(grouping: filteredExpenses, by: { $0.category })
        return ExpenseCategory.allCases.compactMap { category in
            let total = grouped[category]?.reduce(0) { $0 + $1.amount } ?? 0
            if total > 0 { return (category: category, total: total) }
            return nil
        }.sorted { $0.total > $1.total }
    }
    
    var totalSpending: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var dateRangeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)
        if start == end { return start }
        return "\(start) - \(end)"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 총 지출 카드 + 날짜 선택
                    HStack(spacing: 0) {
                        // 왼쪽: Total Spending
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
                            Text("Spending")
                                .font(.subheadline)
                                .foregroundColor(.black.opacity(0.8))
                            Text("$\(totalSpending, specifier: "%.0f")")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        
                        // 구분선
                        Rectangle()
                            .fill(Color.black.opacity(0.2))
                            .frame(width: 1, height: 80)
                        
                        // 오른쪽: Fixed
                        Button(action: { showingRecurring = true }) {
                            VStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Text("Fixed")
                                        .font(.subheadline)
                                        .foregroundColor(.black.opacity(0.9))
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.black.opacity(0.9))
                                }
                                Text("$\(recurringStore.monthlyTotal, specifier: "%.0f")")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.black)
                                Text("/month")
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
                    
                    // 카테고리별 차트
                    if categoryTotals.isEmpty {
                        VStack(spacing: 12) {
                            Text("🐝")
                                .font(.system(size: 40))
                            Text("No expenses in this period!")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("By Category")
                                .font(.headline)
                            
                            ForEach(categoryTotals, id: \.category) { item in
                                CategoryBarRow(
                                    category: item.category,
                                    total: item.total,
                                    totalSpending: totalSpending
                                )
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                    }
                    
                    // 최근 내역
                    if !filteredExpenses.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Transactions")
                                .font(.headline)
                            
                            ForEach(filteredExpenses.reversed()) { expense in
                                HStack {
                                    Text(expense.category.icon)
                                        .font(.title3)
                                        .frame(width: 36, height: 36)
                                        .background(expense.category.color.opacity(0.15))
                                        .cornerRadius(10)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(expense.category.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        if !expense.note.isEmpty {
                                            Text(expense.note)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Text(expense.date, style: .date)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("-$\(expense.amount, specifier: "%.0f")")
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
            .navigationTitle("📊 Spending")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingDatePicker) {
                DateRangePickerView(
                    startDate: $startDate,
                    endDate: $endDate,
                    minDate: store.expenses.map { $0.date }.min() ?? Date()
                )
            }
        }
    }
}

// 날짜 범위 선택 화면
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
    
    // 빠른 선택 옵션들
    var quickOptions: [(label: String, start: Date, end: Date)] {
        let now = Date()
        let calendar = Calendar.current
        
        // 이번 달
        let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        // 지난 달
        let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)!
        let lastMonthEnd = calendar.date(byAdding: .day, value: -1, to: thisMonthStart)!
        
        // 최근 3개월
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: thisMonthStart)!
        
        // 최근 6개월
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: thisMonthStart)!
        
        // 올해
        let thisYearStart = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: 1, day: 1))!
        
        return [
            ("This Month", thisMonthStart, now),
            ("Last Month", lastMonthStart, lastMonthEnd),
            ("Last 3 Months", threeMonthsAgo, now),
            ("Last 6 Months", sixMonthsAgo, now),
            ("This Year", thisYearStart, now),
        ]
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 빠른 선택
                Section("Quick Select") {
                    ForEach(quickOptions, id: \.label) { option in
                        Button(action: {
                            tempStart = option.start
                            tempEnd = option.end
                        }) {
                            HStack {
                                Text(option.label)
                                    .foregroundColor(.primary)
                                Spacer()
                                if Calendar.current.isDate(tempStart, inSameDayAs: option.start) &&
                                   Calendar.current.isDate(tempEnd, inSameDayAs: option.end) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                    }
                }
                
                // 직접 선택
                Section("Custom Range") {
                    DatePicker("Start", selection: $tempStart, in: minDate..., displayedComponents: [.date])
                    DatePicker("End", selection: $tempEnd, in: tempStart..., displayedComponents: [.date])
                }
            }
            .navigationTitle("Select Period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
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

struct CategoryBarRow: View {
    let category: ExpenseCategory
    let total: Double
    let totalSpending: Double
    
    var percentage: Double {
        totalSpending > 0 ? total / totalSpending : 0
    }
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(category.icon)
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(percentage * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("$\(total, specifier: "%.0f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(category.color)
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
