import SwiftUI
import Combine

// MARK: - Recurring Expense Model
struct RecurringExpense: Identifiable, Codable {
    let id: UUID
    var name: String
    var amount: Double
    var category: ExpenseCategory
    
    init(id: UUID = UUID(), name: String, amount: Double, category: ExpenseCategory) {
        self.id = id
        self.name = name
        self.amount = amount
        self.category = category
    }
}

// MARK: - Recurring Store
class RecurringStore: ObservableObject {
    @Published var items: [RecurringExpense] = []
    
    private let key = "beehive_recurring"
    
    init() { load() }
    
    var monthlyTotal: Double {
        items.reduce(0) { $0 + $1.amount }
    }
    
    func add(_ item: RecurringExpense) {
        items.append(item)
        save()
    }
    
    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }
    
    func update(_ item: RecurringExpense) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            save()
        }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([RecurringExpense].self, from: data) {
            items = decoded
        }
    }
}

// MARK: - Recurring View
struct RecurringView: View {
    @ObservedObject var store: RecurringStore
    @State private var showingAdd = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text("Monthly Fixed Total")
                            .fontWeight(.medium)
                        Spacer()
                        Text("$\(store.monthlyTotal, specifier: "%.0f")")
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Fixed Expenses") {
                    if store.items.isEmpty {
                        VStack(spacing: 8) {
                            Text("📋")
                                .font(.system(size: 36))
                            Text("No fixed expenses yet!")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    } else {
                        ForEach(store.items) { item in
                            RecurringRow(item: item, store: store)
                        }
                        .onDelete { store.delete(at: $0) }
                    }
                }
            }
            .navigationTitle("📋 Fixed Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAdd = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddRecurringView(store: store)
            }
        }
    }
}

// MARK: - Recurring Row
struct RecurringRow: View {
    let item: RecurringExpense
    @ObservedObject var store: RecurringStore
    @State private var showingEdit = false
    
    var body: some View {
        HStack {
            Text(item.category.icon)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(item.category.color.opacity(0.15))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .fontWeight(.medium)
                Text(item.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("$\(item.amount, specifier: "%.0f")/mo")
                .fontWeight(.semibold)
                .foregroundColor(.orange)
        }
        .padding(.vertical, 4)
        .onTapGesture { showingEdit = true }
        .sheet(isPresented: $showingEdit) {
            EditRecurringView(item: item, store: store)
        }
    }
}

// MARK: - Add Recurring View
struct AddRecurringView: View {
    @ObservedObject var store: RecurringStore
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var amount = ""
    @State private var selectedCategory: ExpenseCategory = .live
    
    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Name (e.g. Rent, Netflix)", text: $name)
                    TextField("Monthly Amount", text: $amount)
                        .keyboardType(.numberPad)
                }
                
                Section("Category") {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        HStack {
                            Text(category.icon)
                            Text(category.rawValue)
                            Spacer()
                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.orange)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selectedCategory = category }
                    }
                }
            }
            .navigationTitle("Add Fixed Expense")
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
        store.add(RecurringExpense(name: name, amount: amountDouble, category: selectedCategory))
        dismiss()
    }
}

// MARK: - Edit Recurring View
struct EditRecurringView: View {
    let item: RecurringExpense
    @ObservedObject var store: RecurringStore
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var amount: String
    @State private var selectedCategory: ExpenseCategory
    
    init(item: RecurringExpense, store: RecurringStore) {
        self.item = item
        self.store = store
        _name = State(initialValue: item.name)
        _amount = State(initialValue: "\(Int(item.amount))")
        _selectedCategory = State(initialValue: item.category)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Monthly Amount", text: $amount)
                        .keyboardType(.numberPad)
                }
                
                Section("Category") {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        HStack {
                            Text(category.icon)
                            Text(category.rawValue)
                            Spacer()
                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.orange)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selectedCategory = category }
                    }
                }
                
                Section {
                    Button("Delete") {
                        if let index = store.items.firstIndex(where: { $0.id == item.id }) {
                            store.delete(at: IndexSet([index]))
                        }
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Edit Fixed Expense")
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
        var updated = item
        updated = RecurringExpense(id: item.id, name: name, amount: amountDouble, category: selectedCategory)
        store.update(updated)
        dismiss()
    }
}

#Preview {
    RecurringView(store: RecurringStore())
}
