import SwiftUI
import SwiftData
import PhotosUI

struct BabyDetailView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var settings: AppSettings
    @Bindable var baby: Baby
    
    @State private var showingMilkEntry = false
    @State private var showingFoodEntry = false
    @State private var showingPoopEntry = false
    @State private var showingUpdateMeasurements = false
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                VStack(spacing: 15) {
                    ZStack(alignment: .bottomTrailing) {
                        if let data = baby.profileImage, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundStyle(.gray.opacity(0.3))
                                .frame(width: 120, height: 120)
                        }
                        
                        PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                            Image(systemName: "camera.fill")
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        .onChange(of: selectedItem) {
                            Task {
                                if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                                    baby.profileImage = data
                                }
                            }
                        }
                    }
                    
                    VStack(spacing: 5) {
                        Text(baby.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(calculateAge(dob: baby.dob))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 30) {
                        MeasurementView(
                            title: "Weight",
                            value: formatWeight(baby.currentWeight),
                            unit: settings.useMetricSystem ? "kg" : "lb"
                        )
                        Divider().frame(height: 30)
                        MeasurementView(
                            title: "Height",
                            value: formatHeight(baby.currentHeight),
                            unit: settings.useMetricSystem ? "cm" : "in"
                        )
                    }
                    .padding(.top, 5)
                    
                    HStack {
                        Button("Update Measurements") {
                            showingUpdateMeasurements = true
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .tint(.blue)
                        
                        NavigationLink(destination: ChartsView(baby: baby)) {
                            Label("Charts", systemImage: "chart.xyaxis.line")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .tint(.purple)
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 5)
                .padding(.horizontal)
                
                // Quick Actions
                VStack(alignment: .leading) {
                    Text("Quick Actions")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack(spacing: 15) {
                        SingleActionButton(title: "Milk", icon: "drop.fill", color: .blue) {
                            showingMilkEntry = true
                        }
                        SingleActionButton(title: "Food", icon: "carrot.fill", color: .orange) {
                            showingFoodEntry = true
                        }
                        SingleActionButton(title: "Poop", icon: "toilet.fill", color: .brown) {
                            showingPoopEntry = true
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Health Card
                NavigationLink(destination: HealthDashboardView(baby: baby)) {
                    HStack {
                        Image(systemName: "heart.text.square.fill")
                            .font(.title)
                            .foregroundStyle(.red)
                        VStack(alignment: .leading) {
                            Text("Health Records")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("Vaccines & Appointments")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.05), radius: 10)
                    .padding(.horizontal)
                }
                
                // Recent Activity
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Recent Activity")
                            .font(.headline)
                        Spacer()
                        NavigationLink(destination: HistoryView(baby: baby)) {
                            Text("View All")
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal)
                    
                    if baby.milkRecords.isEmpty && baby.foodRecords.isEmpty && baby.poopRecords.isEmpty {
                        ContentUnavailableView("No Activity", systemImage: "clock", description: Text("Start tracking to see history here."))
                            .frame(height: 150)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(getAllRecords().prefix(10), id: \.id) { item in
                                ActivityRow(item: item)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ShareLink(item: ExportManager.generateCSV(for: baby), preview: SharePreview("Export Data", image: Image(systemName: "tablecells"))) {
                        Label("Export CSV", systemImage: "tablecells")
                    }
                    
                    if let backupURL = DataTransferManager.generateJSON(for: [baby]) {
                        ShareLink(item: backupURL) {
                            Label("Backup to Cloud (JSON)", systemImage: "icloud.and.arrow.up")
                        }
                    }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingMilkEntry) { MilkEntryView(baby: baby) }
        .sheet(isPresented: $showingFoodEntry) { FoodEntryView(baby: baby) }
        .sheet(isPresented: $showingPoopEntry) { PoopEntryView(baby: baby) }
        .sheet(isPresented: $showingUpdateMeasurements) { UpdateMeasurementsView(baby: baby) }
    }
    
    private func calculateAge(dob: Date) -> String {
        let components = Calendar.current.dateComponents([.month, .day], from: dob, to: Date())
        if let months = components.month, let days = components.day {
            if months == 0 {
                return "\(days) days old"
            } else {
                return "\(months) months \(days) days old"
            }
        }
        return ""
    }
    
    private func formatWeight(_ kg: Double) -> String {
        if settings.useMetricSystem {
            return String(format: "%.2f", kg)
        } else {
            return String(format: "%.2f", kg * 2.20462)
        }
    }
    
    private func formatHeight(_ cm: Double) -> String {
        if settings.useMetricSystem {
            return String(format: "%.1f", cm)
        } else {
            return String(format: "%.1f", cm / 2.54)
        }
    }
    
    // Helper for unified activity list
    struct ActivityItem: Identifiable {
        let id = UUID()
        let type: String
        let title: String
        let subtitle: String
        let time: Date
        let icon: String
        let color: Color
    }
    
    private func getAllRecords() -> [ActivityItem] {
        var items: [ActivityItem] = []
        
        for r in baby.milkRecords {
            items.append(ActivityItem(type: "Milk", title: "\(Int(r.amountML))ml \(r.type.rawValue)", subtitle: "", time: r.timestamp, icon: "drop.fill", color: .blue))
        }
        for r in baby.foodRecords {
            items.append(ActivityItem(type: "Food", title: "\(r.mealType): \(r.foodItem)", subtitle: "Mood: \(r.mood)", time: r.timestamp, icon: "carrot.fill", color: .orange))
        }
        for r in baby.poopRecords {
            items.append(ActivityItem(type: "Poop", title: r.color.rawValue, subtitle: "", time: r.timestamp, icon: "toilet.fill", color: .brown))
        }
        
        return items.sorted(by: { $0.time > $1.time })
    }
}

struct MeasurementView: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct SingleActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }
}

struct ActivityRow: View {
    let item: BabyDetailView.ActivityItem
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: item.icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(item.color)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text(item.time, style: .time)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.03), radius: 5)
    }
}

struct UpdateMeasurementsView: View {
    @Environment(\.dismiss) var dismiss
    var baby: Baby
    
    @State private var weight = ""
    @State private var height = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date)
                TextField("Weight (kg)", text: $weight)
                    .keyboardType(.decimalPad)
                TextField("Height (cm)", text: $height)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Update Measurements")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let weightVal = Double(weight) ?? baby.currentWeight
                        let heightVal = Double(height) ?? baby.currentHeight
                        
                        baby.currentWeight = weightVal
                        baby.currentHeight = heightVal
                        
                        let measurement = Measurement(date: date, weight: weightVal, height: heightVal)
                        baby.measurements.append(measurement)
                        
                        dismiss()
                    }
                }
            }
            .onAppear {
                weight = String(baby.currentWeight)
                height = String(baby.currentHeight)
            }
        }
    }
}
