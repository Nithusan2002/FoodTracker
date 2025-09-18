import SwiftUI
import CoreData

struct AddFoodView: View {
    @ObservedObject var viewModel: FoodViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var moc

    @State private var name: String = ""
    @State private var calories: Double = 0
    @State private var showingScanner = false
    @State private var scannedCode: String?

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingErrorAlert = false
    
    @State private var searchText = ""
    @State private var filteredFoods: [FoodItem] = []
    
    @State private var showingManualBarcode = false
    @State private var manualBarcode = ""
    
    // 🔹 Holder på strekkoden vi jobber med
    @State private var currentBarcode: String?

    var body: some View {
        NavigationView {
            Form {
                // 🔍 Søkefelt med barcode- og tastatur-knapp
                HStack {
                    TextField("Søk etter mat...", text: $searchText)
                        .onChange(of: searchText) {
                            filterFoods()
                        }
                    Button {
                        showingScanner = true
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                            .font(.title2)
                    }
                    Button {
                        showingManualBarcode.toggle()
                    } label: {
                        Image(systemName: "keyboard")
                            .font(.title2)
                    }
                }

                // 📜 Treffliste fra Core Data
                if !searchText.isEmpty {
                    ForEach(filteredFoods, id: \.objectID) { food in
                        Button {
                            name = food.name ?? ""
                            calories = Double(food.calories)
                            currentBarcode = food.barcode
                            searchText = ""
                        } label: {
                            VStack(alignment: .leading) {
                                Text(food.name ?? "")
                                Text("\(food.calories) kcal")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // ✏️ Manuell strekkode-input
                if showingManualBarcode {
                    HStack {
                        TextField("Skriv inn strekkode", text: $manualBarcode)
                            .keyboardType(.numberPad)
                        Button("Søk") {
                            handleBarcode(manualBarcode)
                        }
                        .disabled(manualBarcode.isEmpty)
                    }
                }

                // 🍽 Food Details
                Section(header: Text("Food Details")) {
                    TextField("Matnavn", text: $name)
                    TextField("Kalorier", value: $calories, format: .number)
                        .keyboardType(.decimalPad)
                }

                if isLoading {
                    ProgressView("Henter produktinfo…")
                }
            }
            .navigationTitle("Add Food")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addFood(name: name, calories: Int(calories), barcode: currentBarcode)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingScanner) {
                BarcodeScannerView { code in
                    scannedCode = code
                    showingScanner = false
                    handleBarcode(code)
                }
            }
            .alert("Feil", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Ukjent feil")
            }
        }
    }

    // 🔍 Filtrer Core Data-historikken
    func filterFoods() {
        let request: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
        request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", searchText)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FoodItem.name, ascending: true)]
        
        do {
            filteredFoods = try moc.fetch(request)
        } catch {
            print("Feil ved henting av matvarer: \(error.localizedDescription)")
        }
    }

    // 📦 Håndter barcode (fra scanner eller manuelt)
    func handleBarcode(_ code: String) {
        currentBarcode = code // lagre strekkoden vi jobber med

        // 1. Sjekk om vi har den i Core Data
        let request: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
        request.predicate = NSPredicate(format: "barcode == %@", code)
        if let match = try? moc.fetch(request).first {
            name = match.name ?? ""
            calories = Double(match.calories)
            return
        }
        // 2. Hvis ikke, hent fra API
        fetchFoodInfo(for: code)
    }

    func fetchFoodInfo(for barcode: String) {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(barcode).json") else { return }

        isLoading = true
        errorMessage = nil

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async { isLoading = false }

            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    errorMessage = "Kunne ikke hente data. Sjekk internettforbindelsen."
                    showingErrorAlert = true
                }
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let product = json["product"] as? [String: Any] {

                let fetchedName = product["product_name"] as? String ?? "Ukjent produkt"
                let nutriments = product["nutriments"] as? [String: Any]
                let kcal = nutriments?["energy-kcal_100g"] as? Double ?? 0

                DispatchQueue.main.async {
                    if fetchedName == "Ukjent produkt" {
                        errorMessage = "Fant ikke produktinformasjon for denne strekkoden."
                        showingErrorAlert = true
                    }
                    self.name = fetchedName
                    self.calories = kcal
                    self.currentBarcode = barcode

                    // 💾 Lagre i Core Data med strekkode
                    viewModel.addFood(name: fetchedName, calories: Int(kcal), barcode: barcode)
                }
            } else {
                DispatchQueue.main.async {
                    errorMessage = "Fant ikke produktinformasjon for denne strekkoden."
                    showingErrorAlert = true
                }
            }
        }.resume()
    }
}
