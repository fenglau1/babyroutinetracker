import SwiftUI
import Charts

struct ChartsView: View {
    var baby: Baby
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Growth Chart
                ChartCard(title: "Growth Trend") {
                    Chart {
                        ForEach(baby.measurements.sorted(by: { $0.date < $1.date })) { m in
                            LineMark(
                                x: .value("Date", m.date),
                                y: .value("Weight", settings.useMetricSystem ? m.weight : m.weight * 2.20462)
                            )
                            .foregroundStyle(.blue)
                            .symbol(by: .value("Type", "Weight"))
                            
                            LineMark(
                                x: .value("Date", m.date),
                                y: .value("Height", settings.useMetricSystem ? m.height : m.height / 2.54)
                            )
                            .foregroundStyle(.green)
                            .symbol(by: .value("Type", "Height"))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 250)
                }
                
                // Milk Chart
                ChartCard(title: "Milk Intake (Last 7 Days)") {
                    Chart {
                        ForEach(getLast7DaysMilk(), id: \.date) { item in
                            BarMark(
                                x: .value("Date", item.date, unit: .day),
                                y: .value("Volume", item.amount)
                            )
                            .foregroundStyle(.blue.gradient)
                        }
                    }
                    .frame(height: 200)
                }
                
                // Food Chart (Meal Frequency)
                ChartCard(title: "Meal Frequency") {
                    Chart {
                        ForEach(getMealFrequency(), id: \.type) { item in
                            BarMark(
                                x: .value("Meal", item.type),
                                y: .value("Count", item.count)
                            )
                            .foregroundStyle(by: .value("Meal", item.type))
                        }
                    }
                    .frame(height: 200)
                }
                
                // Poop Chart (Color Distribution)
                ChartCard(title: "Poop Colors") {
                    Chart {
                        ForEach(getPoopColors(), id: \.color) { item in
                            SectorMark(
                                angle: .value("Count", item.count),
                                innerRadius: .ratio(0.5),
                                angularInset: 1.5
                            )
                            .foregroundStyle(Color(hex: item.hex))
                            .annotation(position: .overlay) {
                                Text("\(item.count)")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .shadow(radius: 1)
                            }
                        }
                    }
                    .frame(height: 200)
                }
            }
            .padding()
        }
        .navigationTitle("Charts & Trends")
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // Helper Data Structs
    struct DailyMilk {
        let date: Date
        let amount: Double
    }
    
    struct MealCount {
        let type: String
        let count: Int
    }
    
    struct PoopCount {
        let color: String
        let hex: String
        let count: Int
    }
    
    // Data Processing Helpers
    func getLast7DaysMilk() -> [DailyMilk] {
        let calendar = Calendar.current
        let today = Date()
        var result: [DailyMilk] = []
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                
                let dailyTotal = baby.milkRecords
                    .filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }
                    .reduce(0) { $0 + $1.amountML }
                
                result.append(DailyMilk(date: startOfDay, amount: dailyTotal))
            }
        }
        return result.reversed()
    }
    
    func getMealFrequency() -> [MealCount] {
        var counts: [String: Int] = [:]
        for record in baby.foodRecords {
            counts[record.mealType, default: 0] += 1
        }
        return counts.map { MealCount(type: $0.key, count: $0.value) }
    }
    
    func getPoopColors() -> [PoopCount] {
        var counts: [PoopColor: Int] = [:]
        for record in baby.poopRecords {
            counts[record.color, default: 0] += 1
        }
        return counts.map { PoopCount(color: $0.key.rawValue, hex: $0.key.colorHex, count: $0.value) }
    }
}

struct ChartCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 5)
            content
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}
