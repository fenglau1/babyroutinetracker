//
//  Baby_RoutineApp.swift
//  Baby Routine
//
//  Created by SF on 22/11/2025.
//

import SwiftUI
import SwiftData

@main
struct Baby_RoutineApp: App {
    @StateObject private var settings = AppSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .preferredColorScheme(settings.isDarkMode ? .dark : .light)
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                }
        }
        .modelContainer(for: [Baby.self, MilkRecord.self, FoodRecord.self, PoopRecord.self, Vaccine.self, Appointment.self, Measurement.self])
    }
}
