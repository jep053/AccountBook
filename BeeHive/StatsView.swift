import SwiftUI

struct StatsView: View {
    @ObservedObject var store: BeeHiveStore
    
    var monthlyExpenses: [Expense] {
        let now = Date()
        let month = Calendar.current.component(.month, from: now)
        let year = Calendar.current.component(.year, from: now)
        return store.expenses.filter {
            Calendar.current.component(.month, from: $0.date) == month &&
            Calendar.current.component(.year, from: $0.date) == year
        }
    }
    
    var categoryTotals: [(category: ExpenseCategory, total: Double)] {
        let grouped = Dictionary(grouping: monthlyExpenses, by: { $0.category })
        return ExpenseCategory.allCases.compactMap { category in
            let total = grouped[category]?.reduce(0) { $0 + $1.amount } ?? 0
            if total > 0 {
                return (category: category, total: total)
            }
            return nil
        }.sorted { $0.total > $1.total }
    }
    
    var monthlyTotal: Double {
        monthlyExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 이번 달 총 지출
                    VStack(spacing: 8) {
                        Text("Total Spending")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        Text("$\(monthlyTotal, specifier: "%.0f")")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.white)
                        Text(currentMonthName)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(Color.yellow.opacity(0.8))
                    .cornerRadius(20)
                    
                    // 카테고리별 바 차트
                    if categoryTotals.isEmpty {
                        VStack(spacing: 12) {
                            Text("🐝")
                                .font(.system(size: 40))
                            Text("No expenses this month yet!")
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
                                    maxTotal: categoryTotals.first?.total ?? 1
                                )
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                    }
                    
                    // 최근 내역
                    if !monthlyExpenses.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent")
                                .font(.headline)
                            
                            ForEach(monthlyExpenses.suffix(5).reversed()) { expense in
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
            .navigationTitle("📊 Stats")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// 카테고리 바 차트 행
struct CategoryBarRow: View {
    let category: ExpenseCategory
    let total: Double
    let maxTotal: Double
    
    var percentage: Double {
        maxTotal > 0 ? total / maxTotal : 0
    }
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(category.icon)
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
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
