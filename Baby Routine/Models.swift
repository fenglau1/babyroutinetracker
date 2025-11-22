import Foundation
import SwiftData

@Model
class Baby {
    var id: UUID
    var name: String
    var dob: Date
    var gender: Gender
    var currentWeight: Double // in kg
    var currentHeight: Double // in cm
    @Attribute(.externalStorage) var profileImage: Data?
    
    // Relationships
    @Relationship(deleteRule: .cascade) var milkRecords: [MilkRecord] = []
    @Relationship(deleteRule: .cascade) var foodRecords: [FoodRecord] = []
    @Relationship(deleteRule: .cascade) var poopRecords: [PoopRecord] = []
    @Relationship(deleteRule: .cascade) var vaccines: [Vaccine] = []
    @Relationship(deleteRule: .cascade) var appointments: [Appointment] = []
    @Relationship(deleteRule: .cascade) var measurements: [Measurement] = []
    
    init(name: String, dob: Date, gender: Gender, currentWeight: Double = 0.0, currentHeight: Double = 0.0, profileImage: Data? = nil) {
        self.id = UUID()
        self.name = name
        self.dob = dob
        self.gender = gender
        self.currentWeight = currentWeight
        self.currentHeight = currentHeight
        self.profileImage = profileImage
    }
}

enum Gender: String, Codable, CaseIterable {
    case boy = "Boy"
    case girl = "Girl"
}

@Model
class Measurement {
    var date: Date
    var weight: Double
    var height: Double
    
    init(date: Date, weight: Double, height: Double) {
        self.date = date
        self.weight = weight
        self.height = height
    }
}

@Model
class MilkRecord {
    var timestamp: Date
    var amountML: Double
    var type: MilkType
    
    init(timestamp: Date, amountML: Double, type: MilkType) {
        self.timestamp = timestamp
        self.amountML = amountML
        self.type = type
    }
}

enum MilkType: String, Codable, CaseIterable {
    case breast = "Breast Milk"
    case formula = "Formula"
}

@Model
class FoodRecord {
    var timestamp: Date
    var foodItem: String
    var notes: String
    var mood: String
    var mealType: String // New field
    
    init(timestamp: Date, foodItem: String, notes: String = "", mood: String = "Happy", mealType: String = "Lunch") {
        self.timestamp = timestamp
        self.foodItem = foodItem
        self.notes = notes
        self.mood = mood
        self.mealType = mealType
    }
}

enum MealType: String, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    
    var icon: String {
        switch self {
        case .breakfast: return "🥞"
        case .lunch: return "🍱"
        case .dinner: return "🍲"
        case .snack: return "🍪"
        }
    }
}

@Model
class PoopRecord {
    var timestamp: Date
    var color: PoopColor
    var notes: String
    
    init(timestamp: Date, color: PoopColor, notes: String = "") {
        self.timestamp = timestamp
        self.color = color
        self.notes = notes
    }
}

enum PoopColor: String, Codable, CaseIterable {
    case yellow = "Yellow"
    case brown = "Brown"
    case green = "Green"
    case black = "Black"
    case red = "Red (See Doctor)"
    case white = "White (See Doctor)"
    
    var colorHex: String {
        switch self {
        case .yellow: return "#FFD700"
        case .brown: return "#8B4513"
        case .green: return "#008000"
        case .black: return "#000000"
        case .red: return "#FF0000"
        case .white: return "#FFFFFF"
        }
    }
}

@Model
class Vaccine {
    var name: String
    var dateAdministered: Date?
    var isCompleted: Bool
    
    init(name: String, isCompleted: Bool = false, dateAdministered: Date? = nil) {
        self.name = name
        self.isCompleted = isCompleted
        self.dateAdministered = dateAdministered
    }
}

@Model
class Appointment {
    var title: String
    var date: Date
    var notes: String
    
    init(title: String, date: Date, notes: String = "") {
        self.title = title
        self.date = date
        self.notes = notes
    }
}
