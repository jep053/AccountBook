import SwiftUI

struct SimulatorView: View {
    @AppStorage("birthday") var birthdayTimestamp: Double = 0
    @AppStorage("retirementAge") var retirementAge: Int = 45
    
    // 입력값
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
    
    // 시뮬레이션 결과
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
            // 4% Rule: 자산이 연 지출의 25배 이상이면 경제적 자유
            let isFreedom = currentAssetValue >= currentExpense * 25
            
            snapshots.append(YearlySnapshot(
                age: age,
                assets: currentAssetValue,
                annualExpenses: currentExpense,
                isFreedom: isFreedom
            ))
            
            if isFreedom && age > currentAge { break }
            
            // 다음 해 계산
            let savingsRate = max(0, annualIncome - currentExpense)
            currentAssetValue = currentAssetValue * (1 + returnRateDecimal) + savingsRate
            currentExpense = currentExpense * (1 + inflationDecimal)
            
            if snapshots.count > 70 { break }
        }
        
        return snapshots
    }
    
    var freedomAge: Int? {
        simulation.first(where: { $0.isFreedom })?.age
    }
    
    var yearsToFreedom: Int? {
        guard let age = freedomAge else { return nil }
        return age - currentAge
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 헤더
                VStack(spacing: 8) {
                    Text("🐝")
                        .font(.system(size: 50))
                    Text("Freedom Simulator")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Based on the 4% Rule")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // 입력 섹션
                VStack(spacing: 16) {
                    inputRow(title: "Current Assets ($)", placeholder: "e.g. 50000", binding: $currentAssets)
                    inputRow(title: "Monthly Income ($)", placeholder: "e.g. 3000", binding: $monthlyIncome)
                    inputRow(title: "Monthly Expenses ($)", placeholder: "e.g. 2000", binding: $monthlyExpenses)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Annual Return (%)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("7", text: $annualReturn)
                                .keyboardType(.decimalPad)
                                .padding(10)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Inflation (%)")
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
                
                // 결과
                if !simulation.isEmpty {
                    // 결과 카드
                    VStack(spacing: 12) {
                        if let years = yearsToFreedom, let age = freedomAge {
                            VStack(spacing: 8) {
                                Text("🍯")
                                    .font(.system(size: 44))
                                Text("Financial Freedom at \(age)!")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("\(years) years from now")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if let snapshot = simulation.first(where: { $0.age == age }) {
                                    Text("Target Assets: $\(snapshot.assets, specifier: "%.0f")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(Color.yellow.opacity(0.15))
                            .cornerRadius(16)
                        } else {
                            VStack(spacing: 8) {
                                Text("😢")
                                    .font(.system(size: 44))
                                Text("Keep saving!")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("Try increasing income or reducing expenses")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(16)
                        }
                    }
                    
                    // 자산 성장 차트
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Asset Growth")
                            .font(.headline)
                        
                        let maxAssets = simulation.map { $0.assets }.max() ?? 1
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .bottom, spacing: 8) {
                                ForEach(simulation, id: \.age) { snapshot in
                                    VStack(spacing: 4) {
                                        if snapshot.isFreedom {
                                            Text("🐝")
                                                .font(.caption2)
                                        }
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(snapshot.isFreedom ? Color.yellow : Color.yellow.opacity(0.4))
                                            .frame(width: 24, height: max(4, CGFloat(snapshot.assets / maxAssets) * 150))
                                        Text("\(snapshot.age)")
                                            .font(.system(size: 8))
                                            .foregroundColor(.secondary)
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
                    
                    // 연도별 테이블
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Year by Year")
                            .font(.headline)
                        
                        ForEach(simulation, id: \.age) { snapshot in
                            HStack {
                                Text("Age \(snapshot.age)")
                                    .font(.subheadline)
                                    .foregroundColor(snapshot.isFreedom ? .yellow : .primary)
                                    .fontWeight(snapshot.isFreedom ? .bold : .regular)
                                Spacer()
                                Text("$\(snapshot.assets, specifier: "%.0f")")
                                    .font(.subheadline)
                                    .foregroundColor(snapshot.isFreedom ? .yellow : .secondary)
                                if snapshot.isFreedom {
                                    Text("🐝")
                                }
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
        .navigationTitle("🐝 Freedom Simulator")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func inputRow(title: String, placeholder: String, binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
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
