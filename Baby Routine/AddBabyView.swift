import SwiftUI
import SwiftData
import PhotosUI

struct AddBabyView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State private var name = ""
    @State private var dob = Date()
    @State private var gender: Gender = .boy
    @State private var weight = ""
    @State private var height = ""
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Picture") {
                    HStack {
                        Spacer()
                        if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundStyle(.gray)
                                .frame(width: 100, height: 100)
                        }
                        Spacer()
                    }
                    
                    PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                        Text("Select Photo")
                            .frame(maxWidth: .infinity)
                    }
                    .onChange(of: selectedItem) {
                        Task {
                            if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                                selectedImageData = data
                            }
                        }
                    }
                }
                
                Section("Baby Details") {
                    TextField("Name", text: $name)
                    DatePicker("Date of Birth", selection: $dob, displayedComponents: .date)
                    Picker("Gender", selection: $gender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Measurements") {
                    TextField("Current Weight (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                    TextField("Current Height (cm)", text: $height)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Baby")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBaby()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveBaby() {
        let weightValue = Double(weight) ?? 0.0
        let heightValue = Double(height) ?? 0.0
        
        let newBaby = Baby(name: name, dob: dob, gender: gender, currentWeight: weightValue, currentHeight: heightValue, profileImage: selectedImageData)
        
        // Add initial measurement
        if weightValue > 0 || heightValue > 0 {
            let measurement = Measurement(date: Date(), weight: weightValue, height: heightValue)
            newBaby.measurements.append(measurement)
        }
        
        modelContext.insert(newBaby)
        dismiss()
    }
}

#Preview {
    AddBabyView()
}
