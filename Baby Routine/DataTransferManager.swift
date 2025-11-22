import Foundation
import SwiftData
import SwiftUI

struct DataTransferManager {
    // DTOs for JSON Serialization
    struct BabyDTO: Codable {
        let id: UUID
        let name: String
        let dob: Date
        let gender: String
        let currentWeight: Double
        let currentHeight: Double
        let profileImage: Data?
        let milkRecords: [MilkRecordDTO]
        let foodRecords: [FoodRecordDTO]
        let poopRecords: [PoopRecordDTO]
        let vaccines: [VaccineDTO]
        let appointments: [AppointmentDTO]
        let measurements: [MeasurementDTO]
    }
    
    struct MilkRecordDTO: Codable {
        let timestamp: Date
        let amountML: Double
        let type: String
    }
    
    struct FoodRecordDTO: Codable {
        let timestamp: Date
        let foodItem: String
        let notes: String
        let mood: String
        let mealType: String
    }
    
    struct PoopRecordDTO: Codable {
        let timestamp: Date
        let color: String
        let notes: String
    }
    
    struct VaccineDTO: Codable {
        let name: String
        let dateAdministered: Date?
        let isCompleted: Bool
    }
    
    struct AppointmentDTO: Codable {
        let title: String
        let date: Date
        let notes: String
    }
    
    struct MeasurementDTO: Codable {
        let date: Date
        let weight: Double
        let height: Double
    }
    
    struct BackupContainer: Codable {
        let version: String
        let timestamp: Date
        let babies: [BabyDTO]
    }
    
    // Export Logic
    static func generateJSON(for babies: [Baby]) -> URL? {
        let dtos = babies.map { baby in
            BabyDTO(
                id: baby.id,
                name: baby.name,
                dob: baby.dob,
                gender: baby.gender.rawValue,
                currentWeight: baby.currentWeight,
                currentHeight: baby.currentHeight,
                profileImage: baby.profileImage,
                milkRecords: baby.milkRecords.map { MilkRecordDTO(timestamp: $0.timestamp, amountML: $0.amountML, type: $0.type.rawValue) },
                foodRecords: baby.foodRecords.map { FoodRecordDTO(timestamp: $0.timestamp, foodItem: $0.foodItem, notes: $0.notes, mood: $0.mood, mealType: $0.mealType) },
                poopRecords: baby.poopRecords.map { PoopRecordDTO(timestamp: $0.timestamp, color: $0.color.rawValue, notes: $0.notes) },
                vaccines: baby.vaccines.map { VaccineDTO(name: $0.name, dateAdministered: $0.dateAdministered, isCompleted: $0.isCompleted) },
                appointments: baby.appointments.map { AppointmentDTO(title: $0.title, date: $0.date, notes: $0.notes) },
                measurements: baby.measurements.map { MeasurementDTO(date: $0.date, weight: $0.weight, height: $0.height) }
            )
        }
        
        let backup = BackupContainer(version: "1.0", timestamp: Date(), babies: dtos)
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(backup)
            
            let fileName = "BabyRoutine_Backup_\(Int(Date().timeIntervalSince1970)).json"
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to generate JSON: \(error)")
            return nil
        }
    }
    
    // Import Logic
    @MainActor
    static func importJSON(from url: URL, context: ModelContext) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let backup = try decoder.decode(BackupContainer.self, from: data)
        
        // Fetch existing babies to check for duplicates
        let descriptor = FetchDescriptor<Baby>()
        let existingBabies = try context.fetch(descriptor)
        
        for dto in backup.babies {
            // Check if baby already exists by ID
            if let existingBaby = existingBabies.first(where: { $0.id == dto.id }) {
                // Update existing baby details if needed (optional, here we prioritize local or merge)
                // For now, we just merge records
                
                // Merge Milk Records
                for r in dto.milkRecords {
                    if !existingBaby.milkRecords.contains(where: { $0.timestamp == r.timestamp }) {
                        existingBaby.milkRecords.append(MilkRecord(timestamp: r.timestamp, amountML: r.amountML, type: MilkType(rawValue: r.type) ?? .formula))
                    }
                }
                
                // Merge Food Records
                for r in dto.foodRecords {
                    if !existingBaby.foodRecords.contains(where: { $0.timestamp == r.timestamp }) {
                        existingBaby.foodRecords.append(FoodRecord(timestamp: r.timestamp, foodItem: r.foodItem, notes: r.notes, mood: r.mood, mealType: r.mealType))
                    }
                }
                
                // Merge Poop Records
                for r in dto.poopRecords {
                    if !existingBaby.poopRecords.contains(where: { $0.timestamp == r.timestamp }) {
                        existingBaby.poopRecords.append(PoopRecord(timestamp: r.timestamp, color: PoopColor(rawValue: r.color) ?? .yellow, notes: r.notes))
                    }
                }
                
                // Merge Vaccines
                for r in dto.vaccines {
                    if !existingBaby.vaccines.contains(where: { $0.name == r.name }) {
                        existingBaby.vaccines.append(Vaccine(name: r.name, isCompleted: r.isCompleted, dateAdministered: r.dateAdministered))
                    }
                }
                
                // Merge Appointments
                for r in dto.appointments {
                    if !existingBaby.appointments.contains(where: { $0.date == r.date && $0.title == r.title }) {
                        existingBaby.appointments.append(Appointment(title: r.title, date: r.date, notes: r.notes))
                    }
                }
                
                // Merge Measurements
                for r in dto.measurements {
                    if !existingBaby.measurements.contains(where: { $0.date == r.date }) {
                        existingBaby.measurements.append(Measurement(date: r.date, weight: r.weight, height: r.height))
                    }
                }
                
            } else {
                // Create new Baby if not found
                let newBaby = Baby(
                    name: dto.name,
                    dob: dto.dob,
                    gender: Gender(rawValue: dto.gender) ?? .boy,
                    currentWeight: dto.currentWeight,
                    currentHeight: dto.currentHeight,
                    profileImage: dto.profileImage
                )
                // Assign the ID from the DTO to maintain consistency
                newBaby.id = dto.id
                
                // Add Records
                for r in dto.milkRecords {
                    newBaby.milkRecords.append(MilkRecord(timestamp: r.timestamp, amountML: r.amountML, type: MilkType(rawValue: r.type) ?? .formula))
                }
                for r in dto.foodRecords {
                    newBaby.foodRecords.append(FoodRecord(timestamp: r.timestamp, foodItem: r.foodItem, notes: r.notes, mood: r.mood, mealType: r.mealType))
                }
                for r in dto.poopRecords {
                    newBaby.poopRecords.append(PoopRecord(timestamp: r.timestamp, color: PoopColor(rawValue: r.color) ?? .yellow, notes: r.notes))
                }
                for r in dto.vaccines {
                    newBaby.vaccines.append(Vaccine(name: r.name, isCompleted: r.isCompleted, dateAdministered: r.dateAdministered))
                }
                for r in dto.appointments {
                    newBaby.appointments.append(Appointment(title: r.title, date: r.date, notes: r.notes))
                }
                for r in dto.measurements {
                    newBaby.measurements.append(Measurement(date: r.date, weight: r.weight, height: r.height))
                }
                
                context.insert(newBaby)
            }
        }
    }
}
