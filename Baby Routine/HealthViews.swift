import SwiftUI
import SwiftData

struct HealthDashboardView: View {
    @Environment(\.modelContext) var modelContext
    @Bindable var baby: Baby
    @State private var showingAddAppointment = false
    @State private var showingAddVaccine = false
    @State private var editingAppointment: Appointment?
    
    var body: some View {
        List {
            Section("Upcoming Appointments") {
                if baby.appointments.isEmpty {
                    Text("No upcoming appointments")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(baby.appointments.sorted(by: { $0.date < $1.date })) { appointment in
                        Button(action: { editingAppointment = appointment }) {
                            VStack(alignment: .leading) {
                                Text(appointment.title)
                                    .font(.headline)
                                Text(appointment.date, style: .date)
                                Text(appointment.date, style: .time)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                    .onDelete(perform: deleteAppointment)
                }
                Button("Add Appointment") {
                    showingAddAppointment = true
                }
            }
            
            Section("Vaccines") {
                if baby.vaccines.isEmpty {
                    Text("No vaccines recorded")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(baby.vaccines) { vaccine in
                        HStack {
                            Image(systemName: vaccine.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(vaccine.isCompleted ? .green : .gray)
                                .onTapGesture {
                                    vaccine.isCompleted.toggle()
                                }
                            Text(vaccine.name)
                            Spacer()
                            if let date = vaccine.dateAdministered {
                                Text(date, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteVaccine)
                }
                Button("Add Vaccine") {
                    showingAddVaccine = true
                }
            }
        }
        .navigationTitle("Health Record")
        .sheet(isPresented: $showingAddAppointment) {
            AddAppointmentView(baby: baby)
        }
        .sheet(item: $editingAppointment) { appointment in
            AddAppointmentView(baby: baby, existingAppointment: appointment)
        }
        .sheet(isPresented: $showingAddVaccine) {
            AddVaccineView(baby: baby)
        }
    }
    
    private func deleteAppointment(offsets: IndexSet) {
        for index in offsets {
            let appointment = baby.appointments.sorted(by: { $0.date < $1.date })[index]
            modelContext.delete(appointment)
        }
    }
    
    private func deleteVaccine(offsets: IndexSet) {
        for index in offsets {
            let vaccine = baby.vaccines[index]
            modelContext.delete(vaccine)
        }
    }
}

struct AddAppointmentView: View {
    @Environment(\.dismiss) var dismiss
    var baby: Baby
    var existingAppointment: Appointment?
    
    @State private var title = ""
    @State private var date = Date()
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                DatePicker("Date", selection: $date)
                TextField("Notes", text: $notes, axis: .vertical)
            }
            .navigationTitle(existingAppointment == nil ? "New Appointment" : "Edit Appointment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let appointment = existingAppointment {
                            appointment.title = title
                            appointment.date = date
                            appointment.notes = notes
                        } else {
                            let appointment = Appointment(title: title, date: date, notes: notes)
                            baby.appointments.append(appointment)
                            
                            // Schedule notification 1 hour before
                            let notificationDate = date.addingTimeInterval(-3600)
                            if notificationDate > Date() {
                                NotificationManager.shared.scheduleNotification(
                                    title: "Upcoming Appointment",
                                    body: "\(title) is in 1 hour.",
                                    date: notificationDate,
                                    identifier: UUID().uuidString
                                )
                            }
                        }
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                if let appointment = existingAppointment {
                    title = appointment.title
                    date = appointment.date
                    notes = appointment.notes
                }
            }
        }
    }
}

struct AddVaccineView: View {
    @Environment(\.dismiss) var dismiss
    var baby: Baby
    
    @State private var name = ""
    @State private var isCompleted = false
    @State private var date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Vaccine Name", text: $name)
                Toggle("Completed", isOn: $isCompleted)
                if isCompleted {
                    DatePicker("Date Administered", selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle("Add Vaccine")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let vaccine = Vaccine(name: name, isCompleted: isCompleted, dateAdministered: isCompleted ? date : nil)
                        baby.vaccines.append(vaccine)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
