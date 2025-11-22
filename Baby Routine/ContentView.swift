import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var settings: AppSettings
    @Query var babies: [Baby]
    @State private var showingAddBaby = false
    @State private var showingSettings = false
    @State private var isImporting = false
    @State private var importError: String?
    @State private var showingImportError = false
    
    var body: some View {
        NavigationStack {
            List {
                if babies.isEmpty {
                    ContentUnavailableView("No Babies Added", systemImage: "stroller", description: Text("Tap the + button to add your baby."))
                } else {
                    ForEach(babies) { baby in
                        NavigationLink(destination: BabyDetailView(baby: baby)) {
                            HStack {
                                if let data = baby.profileImage, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundStyle(.gray)
                                        .frame(width: 50, height: 50)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(baby.name)
                                        .font(.headline)
                                    Text(calculateAge(dob: baby.dob)) // Assuming calculateAge is defined elsewhere or will be added
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteBabies)
                }
            }
            .navigationTitle("Baby Routine")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button(action: { showingSettings = true }) {
                            Label("Settings", systemImage: "gear")
                        }
                        Button(action: { isImporting = true }) {
                            Label("Import Backup", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Label("Menu", systemImage: "line.3.horizontal")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddBaby = true }) {
                        Label("Add Baby", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBaby) {
                AddBabyView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    Task {
                        do {
                            if url.startAccessingSecurityScopedResource() {
                                try await DataTransferManager.importJSON(from: url, context: modelContext) // Assuming DataTransferManager is defined elsewhere
                                url.stopAccessingSecurityScopedResource()
                            }
                        } catch {
                            importError = error.localizedDescription
                            showingImportError = true
                        }
                    }
                case .failure(let error):
                    importError = error.localizedDescription
                    showingImportError = true
                }
            }
            .alert("Import Failed", isPresented: $showingImportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importError ?? "Unknown error")
            }
        }
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
    
    private func deleteBabies(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(babies[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Baby.self, inMemory: true)
        .environmentObject(AppSettings())
}
