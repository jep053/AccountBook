import SwiftUI

struct SimulatorView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @AppStorage("birthday") var birthdayTimestamp: Double = 0
    @AppStorage("retirementAge") var retirementAge: Int = 45
    
    @State private var currentAssets: String = ""
    @State private var monthlyIncome: String = ""
    @State private var monthlyExpenses: String = ""
    @State private var annualReturn: String = "7"
    @State private var inflationRate: String = "3"
    
    var currentAge: Int {
        guard birthdayTimestamp > 0 else { return 25 }
        let birthday = Date(timeIntervalSince1970: birthdayTimestamp)
        return Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 25
    }
    
    struct YearlySnapshot {
        let age: Int
        let assets: Double
        let annualExpenses: Double
        let isFreedom: Bool
    }
    
    var simulation: [YearlySnapshot] {
        guard let assets = Double(currentAssets),
              let income = Double(monthlyIncome),
              let expenses = Double(monthlyExpenses),
              let returnRate = Double(annualReturn),
              let inflation = Double(inflationRate) else { return [] }
        
        var snapshots: [YearlySnapshot] = []
        var currentAssetValue = assets
        let annualIncome = income * 12
        let annualExpense = expenses * 12
        var currentExpense = annualExpense
        let returnRateDecimal = returnRate / 100
        let inflationDecimal = inflation / 100
        
        for age in currentAge...90 {
            let isFreedom = currentAssetValue >= currentExpense * 25
            snapshots.append(YearlySnapshot(age: age, assets: currentAssetValue, annualExpenses: currentExpense, isFreedom: isFreedom))
            if isFreedom && age > currentAge { break }
            let savingsRate = max(0, annualIncome - currentExpense)
            currentAssetValue = currentAssetValue * (1 + returnRateDecimal) + savingsRate
            currentExpense = currentExpense * (1 + inflationDecimal)
            if snapshots.count > 70 { break }
        }
        return snapshots
    }
    
    var freedomAge: Int? { simulation.first(where: { $0.isFreedom })?.age }
    
    var yearsToFreedom: Int? {
        guard let age = freedomAge else { return nil }
        return age - currentAge
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("🐝").font(.system(size: 50))
                    // ✅ Fix
                    Text(L("simulator.header.title"))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(L("simulator.header.subtitle"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                VStack(spacing: 16) {
                    inputRow(title: L("simulator.input.currentAssets"),
                             placeholder: L("simulator.input.currentAssets.placeholder"),
                             binding: $currentAssets)
                    inputRow(title: L("simulator.input.monthlyIncome"),
                             placeholder: L("simulator.input.monthlyIncome.placeholder"),
                             binding: $monthlyIncome)
                    inputRow(title: L("simulator.input.monthlyExpenses"),
                             placeholder: L("simulator.input.monthlyExpenses.placeholder"),
                             binding: $monthlyExpenses)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            // ✅ Fix
                            Text(L("simulator.input.annualReturn"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("7", text: $annualReturn)
                                .keyboardType(.decimalPad)
                                .padding(10)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            // ✅ Fix
                            Text(L("simulator.input.inflation"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("3", text: $inflationRate)
                                .keyboardType(.decimalPad)
                                .padding(10)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                
                if !simulation.isEmpty {
                    VStack(spacing: 12) {
                        if let years = yearsToFreedom, let age = freedomAge {
                            VStack(spacing: 8) {
                                Text("🍯").font(.system(size: 44))
                                Text(String(format: L("simulator.result.freedom"), age))
                                    .font(.title3).fontWeight(.bold)
                                Text(String(format: L("simulator.result.yearsFromNow"), years))
                                    .font(.subheadline).foregroundColor(.secondary)
                                if let snapshot = simulation.first(where: { $0.age == age }) {
                                    Text(String(format: L("simulator.result.targetAssets"), formatCurrency(snapshot.assets)))
                                        .font(.caption).foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(Color.yellow.opacity(0.15))
                            .cornerRadius(16)
                        } else {
                            VStack(spacing: 8) {
                                Text("😢").font(.system(size: 44))
                                // ✅ Fix
                                Text(L("simulator.result.keepSaving"))
                                    .font(.title3).fontWeight(.bold)
                                Text(L("simulator.result.keepSaving.subtitle"))
                                    .font(.caption).foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(16)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // ✅ Fix
                        Text(L("simulator.chart.title")).font(.headline)
                        let maxAssets = simulation.map { $0.assets }.max() ?? 1
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .bottom, spacing: 8) {
                                ForEach(simulation, id: \.age) { snapshot in
                                    VStack(spacing: 4) {
                                        if snapshot.isFreedom { Text("🐝").font(.caption2) }
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(snapshot.isFreedom ? Color.yellow : Color.yellow.opacity(0.4))
                                            .frame(width: 24, height: max(4, CGFloat(snapshot.assets / maxAssets) * 150))
                                        Text("\(snapshot.age)").font(.system(size: 8)).foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 180)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // ✅ Fix
                        Text(L("simulator.table.title")).font(.headline)
                        ForEach(simulation, id: \.age) { snapshot in
                            HStack {
                                Text(String(format: L("simulator.table.age"), snapshot.age))
                                    .font(.subheadline)
                                    .foregroundColor(snapshot.isFreedom ? .yellow : .primary)
                                    .fontWeight(snapshot.isFreedom ? .bold : .regular)
                                Spacer()
                                Text(formatCurrency(snapshot.assets))
                                    .font(.subheadline)
                                    .foregroundColor(snapshot.isFreedom ? .yellow : .secondary)
                                if snapshot.isFreedom { Text("🐝") }
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
        // ✅ Fix
        .navigationTitle(L("simulator.title"))
        .navigationBarTitleDisplayMode(.inline)
        .refreshOnLanguageChange()
    }
    
    func inputRow(title: String, placeholder: String, binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            TextField(placeholder, text: binding)
                .keyboardType(.numberPad)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }
}

#Preview {
    NavigationView {
        SimulatorView()
    }
}
