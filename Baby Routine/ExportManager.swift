import Foundation
import SwiftUI

struct ExportManager {
    static func generateCSV(for baby: Baby) -> URL {
        var csvString = "Type,Date,Time,Details,Notes,Extra\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        // Milk
        for record in baby.milkRecords {
            let date = dateFormatter.string(from: record.timestamp)
            let line = "Milk,\(date),\(record.amountML)ml,\(record.type.rawValue),,\n"
            csvString.append(line)
        }
        
        // Food
        for record in baby.foodRecords {
            let date = dateFormatter.string(from: record.timestamp)
            let line = "Food,\(date),\(record.foodItem),\(record.notes),Mood: \(record.mood)\n"
            csvString.append(line)
        }
        
        // Poop
        for record in baby.poopRecords {
            let date = dateFormatter.string(from: record.timestamp)
            let line = "Poop,\(date),\(record.color.rawValue),\(record.notes),\n"
            csvString.append(line)
        }
        
        // Measurements
        for record in baby.measurements {
            let date = dateFormatter.string(from: record.date)
            let line = "Growth,\(date),Weight: \(record.weight)kg,Height: \(record.height)cm,,\n"
            csvString.append(line)
        }
        
        // Save to temporary file
        let fileName = "\(baby.name)_Export.csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: path, atomically: true, encoding: .utf8)
        } catch {
            print("Error creating CSV: \(error)")
        }
        
        return path
    }
}
