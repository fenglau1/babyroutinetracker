import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) var modelContext
    @Bindable var baby: Baby
    
    @State private var selectedTab = 0
    @State private var sortAscending = false
    @State private var editingMilk: MilkRecord?
    @State private var editingFood: FoodRecord?
    @State private var editingPoop: PoopRecord?
    
    var body: some View {
        VStack {
            Picker("Type", selection: $selectedTab) {
                Text("Milk").tag(0)
                Text("Food").tag(1)
                Text("Poop").tag(2)
                Text("Growth").tag(3)
            }
            .pickerStyle(.segmented)
            .padding()
            
            List {
                if selectedTab == 0 {
                    ForEach(sortedMilkRecords) { record in
                        Button(action: { editingMilk = record }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(record.type.rawValue)
                                        .font(.headline)
                                    Text(record.timestamp, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(record.timestamp, style: .time)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(Int(record.amountML)) ml")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.blue)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                    .onDelete(perform: deleteMilk)
                } else if selectedTab == 1 {
                    ForEach(sortedFoodRecords) { record in
                        Button(action: { editingFood = record }) {
                            HStack {
                                Text(record.mealType.first?.description ?? "🍽️")
                                    .font(.title2)
                                VStack(alignment: .leading) {
                                    Text(record.foodItem)
                                        .font(.headline)
                                    Text(record.timestamp, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(record.mood)
                                    .font(.title2)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                    .onDelete(perform: deleteFood)
                } else if selectedTab == 2 {
                    ForEach(sortedPoopRecords) { record in
                        Button(action: { editingPoop = record }) {
                            HStack {
                                Circle()
                                    .fill(Color(hex: record.color.colorHex))
                                    .frame(width: 20, height: 20)
                                VStack(alignment: .leading) {
                                    Text(record.color.rawValue)
                                        .font(.headline)
                                    Text(record.timestamp, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                    .onDelete(perform: deletePoop)
                } else if selectedTab == 3 {
                    ForEach(sortedMeasurements) { record in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(record.date, style: .date)
                                    .font(.headline)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(record.weight, specifier: "%.2f") kg")
                                Text("\(record.height, specifier: "%.1f") cm")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteMeasurement)
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { sortAscending = true }) {
                        Label("Oldest First", systemImage: "arrow.up")
                    }
                    Button(action: { sortAscending = false }) {
                        Label("Newest First", systemImage: "arrow.down")
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
            }
        }
        .sheet(item: $editingMilk) { record in
            MilkEntryView(baby: baby, existingRecord: record)
        }
        .sheet(item: $editingFood) { record in
            FoodEntryView(baby: baby, existingRecord: record)
        }
        .sheet(item: $editingPoop) { record in
            PoopEntryView(baby: baby, existingRecord: record)
        }
    }
    
    // Sorting Logic
    var sortedMilkRecords: [MilkRecord] {
        baby.milkRecords.sorted { sortAscending ? $0.timestamp < $1.timestamp : $0.timestamp > $1.timestamp }
    }
    
    var sortedFoodRecords: [FoodRecord] {
        baby.foodRecords.sorted { sortAscending ? $0.timestamp < $1.timestamp : $0.timestamp > $1.timestamp }
    }
    
    var sortedPoopRecords: [PoopRecord] {
        baby.poopRecords.sorted { sortAscending ? $0.timestamp < $1.timestamp : $0.timestamp > $1.timestamp }
    }
    
    var sortedMeasurements: [Measurement] {
        baby.measurements.sorted { sortAscending ? $0.date < $1.date : $0.date > $1.date }
    }
    
    // Deletion Logic
    func deleteMilk(at offsets: IndexSet) {
        withAnimation {
            let sorted = sortedMilkRecords
            offsets.map { sorted[$0] }.forEach { record in
                modelContext.delete(record)
                if let index = baby.milkRecords.firstIndex(of: record) {
                    baby.milkRecords.remove(at: index)
                }
            }
        }
    }
    
    func deleteFood(at offsets: IndexSet) {
        withAnimation {
            let sorted = sortedFoodRecords
            offsets.map { sorted[$0] }.forEach { record in
                modelContext.delete(record)
                if let index = baby.foodRecords.firstIndex(of: record) {
                    baby.foodRecords.remove(at: index)
                }
            }
        }
    }
    
    func deletePoop(at offsets: IndexSet) {
        withAnimation {
            let sorted = sortedPoopRecords
            offsets.map { sorted[$0] }.forEach { record in
                modelContext.delete(record)
                if let index = baby.poopRecords.firstIndex(of: record) {
                    baby.poopRecords.remove(at: index)
                }
            }
        }
    }
    
    func deleteMeasurement(at offsets: IndexSet) {
        withAnimation {
            let sorted = sortedMeasurements
            offsets.map { sorted[$0] }.forEach { record in
                modelContext.delete(record)
                if let index = baby.measurements.firstIndex(of: record) {
                    baby.measurements.remove(at: index)
                }
            }
        }
    }
}
