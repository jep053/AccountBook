import SwiftUI
import Combine

// MARK: - Asset Models
struct Asset: Identifiable, Codable {
    let id: UUID
    var name: String
    var amount: Double
    var type: AssetType
    
    init(id: UUID = UUID(), name: String, amount: Double, type: AssetType) {
        self.id = id
        self.name = name
        self.amount = amount
        self.type = type
    }
}

enum AssetType: String, CaseIterable, Codable {
    case bankSavings = "Bank Savings"
    case bankDeposit = "Bank Deposit"
    case stocks = "Stocks & ETF"
    case retirement = "Retirement"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .bankSavings: return "🏦"
        case .bankDeposit: return "💰"
        case .stocks: return "📈"
        case .retirement: return "🏖️"
        case .other: return "📦"
        }
    }
    
    var color: Color {
        switch self {
        case .bankSavings: return .blue
        case .bankDeposit: return .green
        case .stocks: return .orange
        case .retirement: return .purple
        case .other: return .gray
        }
    }
}

// MARK: - Assets Store
class AssetsStore: ObservableObject {
    @Published var assets: [Asset] = []
    
    private let key = "beehive_assets"
    
    init() { load() }
    
    var totalAssets: Double {
        assets.reduce(0) { $0 + $1.amount }
    }
    
    var assetsByType: [(type: AssetType, total: Double)] {
        let grouped = Dictionary(grouping: assets, by: { $0.type })
        return AssetType.allCases.compactMap { type in
            let total = grouped[type]?.reduce(0) { $0 + $1.amount } ?? 0
            if total > 0 { return (type: type, total: total) }
            return nil
        }.sorted { $0.total > $1.total }
    }
    
    func addAsset(_ asset: Asset) {
        assets.append(asset)
        save()
    }
    
    func deleteAsset(at offsets: IndexSet) {
        assets.remove(atOffsets: offsets)
        save()
    }
    
    func updateAsset(_ asset: Asset) {
        if let index = assets.firstIndex(where: { $0.id == asset.id }) {
            assets[index] = asset
            save()
        }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(assets) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Asset].self, from: data) {
            assets = decoded
        }
    }
}

// MARK: - Assets View
struct AssetsView: View {
    @StateObject private var store = AssetsStore()
    @State private var showingAddAsset = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 총 자산 카드
                    VStack(spacing: 8) {
                        Text("Total Assets")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        Text("$\(store.totalAssets, specifier: "%.0f")")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(Color.green.gradient)
                    .cornerRadius(20)
                    
                    // 카테고리별 요약
                    if !store.assetsByType.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("By Category")
                                .font(.headline)
                            
                            ForEach(store.assetsByType, id: \.type) { item in
                                HStack {
                                    Text(item.type.icon)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .background(item.type.color.opacity(0.15))
                                        .cornerRadius(12)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.type.rawValue)
                                            .fontWeight(.medium)
                                        Text("\(Int(item.total / store.totalAssets * 100))%")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("$\(item.total, specifier: "%.0f")")
                                        .fontWeight(.semibold)
                                        .foregroundColor(item.type.color)
                                }
                                Divider()
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                    }
                    
                    // 자산 목록
                    VStack(alignment: .leading, spacing: 12) {
                        Text("All Assets")
                            .font(.headline)
                        
                        if store.assets.isEmpty {
                            VStack(spacing: 8) {
                                Text("🏦")
                                    .font(.system(size: 40))
                                Text("No assets yet!")
                                    .foregroundColor(.secondary)
                                Text("Tap + to add your first asset")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        } else {
                            ForEach(store.assets) { asset in
                                AssetRow(asset: asset, store: store)
                                Divider()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                }
                .padding()
            }
            .navigationTitle("🏦 Assets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddAsset = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
            }
            .sheet(isPresented: $showingAddAsset) {
                AddAssetView(store: store)
            }
        }
    }
}

// MARK: - Asset Row
struct AssetRow: View {
    let asset: Asset
    @ObservedObject var store: AssetsStore
    @State private var showingEdit = false
    
    var body: some View {
        HStack {
            Text(asset.type.icon)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(asset.type.color.opacity(0.15))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(asset.name)
                    .fontWeight(.medium)
                Text(asset.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("$\(asset.amount, specifier: "%.0f")")
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
        .onTapGesture { showingEdit = true }
        .sheet(isPresented: $showingEdit) {
            EditAssetView(asset: asset, store: store)
        }
    }
}

// MARK: - Add Asset View
struct AddAssetView: View {
    @ObservedObject var store: AssetsStore
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var amount = ""
    @State private var selectedType: AssetType = .bankSavings
    
    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Asset name (e.g. Chase Savings)", text: $name)
                    TextField("Amount", text: $amount)
                        .keyboardType(.numberPad)
                }
                
                Section("Type") {
                    ForEach(AssetType.allCases, id: \.self) { type in
                        HStack {
                            Text(type.icon)
                            Text(type.rawValue)
                            Spacer()
                            if selectedType == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selectedType = type }
                    }
                }
            }
            .navigationTitle("Add Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.bold)
                        .disabled(name.isEmpty || amount.isEmpty)
                }
            }
        }
    }
    
    func save() {
        guard let amountDouble = Double(amount), !name.isEmpty else { return }
        store.addAsset(Asset(name: name, amount: amountDouble, type: selectedType))
        dismiss()
    }
}

// MARK: - Edit Asset View
struct EditAssetView: View {
    let asset: Asset
    @ObservedObject var store: AssetsStore
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var amount: String
    @State private var selectedType: AssetType
    
    init(asset: Asset, store: AssetsStore) {
        self.asset = asset
        self.store = store
        _name = State(initialValue: asset.name)
        _amount = State(initialValue: "\(Int(asset.amount))")
        _selectedType = State(initialValue: asset.type)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Asset name", text: $name)
                    TextField("Amount", text: $amount)
                        .keyboardType(.numberPad)
                }
                
                Section("Type") {
                    ForEach(AssetType.allCases, id: \.self) { type in
                        HStack {
                            Text(type.icon)
                            Text(type.rawValue)
                            Spacer()
                            if selectedType == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selectedType = type }
                    }
                }
                
                Section {
                    Button("Delete Asset") {
                        if let index = store.assets.firstIndex(where: { $0.id == asset.id }) {
                            store.deleteAsset(at: IndexSet([index]))
                        }
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Edit Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.bold)
                        .disabled(name.isEmpty || amount.isEmpty)
                }
            }
        }
    }
    
    func save() {
        guard let amountDouble = Double(amount) else { return }
        var updated = asset
        updated = Asset(id: asset.id, name: name, amount: amountDouble, type: selectedType)
        store.updateAsset(updated)
        dismiss()
    }
}

#Preview {
    AssetsView()
}
