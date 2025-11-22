import SwiftUI
import SwiftData

struct MilkEntryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    var baby: Baby
    var existingRecord: MilkRecord? // Optional for editing
    
    @State private var amount = 100.0
    @State private var type: MilkType = .formula
    @State private var date = Date()
    @State private var scheduleReminder = false
    @State private var reminderDate = Date().addingTimeInterval(3 * 60 * 60)
    
    let quickAmounts = [60.0, 90.0, 120.0, 150.0, 180.0]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    DatePicker("Time", selection: $date)
                    Picker("Type", selection: $type) {
                        ForEach(MilkType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    VStack {
                        HStack {
                            Text("Amount")
                            Spacer()
                            TextField("Amount", value: $amount, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("ml")
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(quickAmounts, id: \.self) { val in
                                    Button("\(Int(val))") {
                                        amount = val
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(amount == val ? .blue : .secondary)
                                }
                            }
                        }
                        .padding(.top, 5)
                        
                        Stepper("Adjust", value: $amount, step: 5)
                    }
                    
                    if existingRecord == nil { // Only show reminder for new entries
                        Toggle("Schedule Reminder", isOn: $scheduleReminder)
                        if scheduleReminder {
                            DatePicker("Remind at", selection: $reminderDate, displayedComponents: .hourAndMinute)
                        }
                    }
                }
            }
            .navigationTitle(existingRecord == nil ? "Log Milk" : "Edit Milk")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let record = existingRecord {
                            // Update existing
                            record.timestamp = date
                            record.amountML = amount
                            record.type = type
                        } else {
                            // Create new
                            let record = MilkRecord(timestamp: date, amountML: amount, type: type)
                            baby.milkRecords.append(record)
                            
                            if scheduleReminder {
                                NotificationManager.shared.scheduleNotification(
                                    title: "Feeding Time",
                                    body: "Time for the next feed!",
                                    date: reminderDate,
                                    identifier: UUID().uuidString
                                )
                            }
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let record = existingRecord {
                    amount = record.amountML
                    type = record.type
                    date = record.timestamp
                }
            }
        }
    }
}

struct FoodEntryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    var baby: Baby
    var existingRecord: FoodRecord?
    
    @State private var foodItem = ""
    @State private var notes = ""
    @State private var mood = "😊"
    @State private var mealType = "Lunch"
    @State private var date = Date()
    
    let moods = ["😊", "😐", "😫", "😭", "😴", "😋"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    DatePicker("Time", selection: $date)
                    
                    VStack(alignment: .leading) {
                        Text("Meal Type")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(MealType.allCases, id: \.self) { meal in
                                    Button(action: { mealType = meal.rawValue }) {
                                        VStack {
                                            Text(meal.icon).font(.title)
                                            Text(meal.rawValue).font(.caption)
                                        }
                                        .frame(width: 70, height: 70)
                                        .background(mealType == meal.rawValue ? Color.orange.opacity(0.2) : Color.gray.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(mealType == meal.rawValue ? Color.orange : Color.clear, lineWidth: 2)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    
                    TextField("Food Item", text: $foodItem)
                    
                    VStack(alignment: .leading) {
                        Text("Mood")
                        Picker("Mood", selection: $mood) {
                            ForEach(moods, id: \.self) { m in
                                Text(m).tag(m)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(existingRecord == nil ? "Log Food" : "Edit Food")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let record = existingRecord {
                            record.timestamp = date
                            record.foodItem = foodItem
                            record.notes = notes
                            record.mood = mood
                            record.mealType = mealType
                        } else {
                            let record = FoodRecord(timestamp: date, foodItem: foodItem, notes: notes, mood: mood, mealType: mealType)
                            baby.foodRecords.append(record)
                        }
                        dismiss()
                    }
                    .disabled(foodItem.isEmpty)
                }
            }
            .onAppear {
                if let record = existingRecord {
                    foodItem = record.foodItem
                    notes = record.notes
                    mood = record.mood
                    mealType = record.mealType
                    date = record.timestamp
                }
            }
        }
    }
}

struct PoopEntryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    var baby: Baby
    var existingRecord: PoopRecord?
    
    @State private var color: PoopColor = .yellow
    @State private var notes = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    DatePicker("Time", selection: $date)
                    
                    VStack(alignment: .leading) {
                        Text("Color")
                        HStack {
                            ForEach(PoopColor.allCases, id: \.self) { c in
                                Circle()
                                    .fill(Color(hex: c.colorHex))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: color == c ? 3 : 0.5)
                                    )
                                    .onTapGesture {
                                        color = c
                                    }
                            }
                        }
                        .padding(.vertical, 5)
                        Text(color.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(existingRecord == nil ? "Log Poop" : "Edit Poop")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let record = existingRecord {
                            record.timestamp = date
                            record.color = color
                            record.notes = notes
                        } else {
                            let record = PoopRecord(timestamp: date, color: color, notes: notes)
                            baby.poopRecords.append(record)
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let record = existingRecord {
                    color = record.color
                    notes = record.notes
                    date = record.timestamp
                }
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
