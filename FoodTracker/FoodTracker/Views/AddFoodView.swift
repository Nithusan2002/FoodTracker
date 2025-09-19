import SwiftUI
import CoreData

// MARK: - Nutrient-modell og enum

struct Nutrient: Identifiable {
    let id = UUID()
    let key: String
    let name: String
    let unit: String
    let valuePerGram: Double
    let valuePerServing: Double?
}

enum PortionMode: String, CaseIterable {
    case gram = "Gram"
    case portion = "Porsjon"
}

struct AddFoodView: View {
    @ObservedObject var viewModel: FoodViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var moc

    @State private var name: String = ""
    @State private var calories: Double = 0
    @State private var currentBarcode: String?

    @State private var showingScanner = false
    @State private var scannedCode: String?
    @State private var showingManualBarcode = false
    @State private var manualBarcode = ""

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingErrorAlert = false

    @State private var searchText = ""
    @State private var filteredFoods: [FoodItem] = []

    @State private var nutrients: [Nutrient] = []
    @State private var portionMode: PortionMode = .gram
    @State private var multiplier: Double = 100
    @State private var portionSizePerServing: Double = 0

    var body: some View {
        NavigationView {
            Form {
                searchAndScanSection
                historyResultsSection
                manualBarcodeSection
                foodInfoSection
                portionSection
                nutrientsSection

                if isLoading {
                    ProgressView("Henter produktinfo…")
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        calories = currentCaloriesTotal()
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

    private var searchAndScanSection: some View {
        HStack {
            TextField("Søk etter mat...", text: $searchText)
                .onChange(of: searchText) {
                    filterFoods()
                }
            Button { showingScanner = true } label: {
                Image(systemName: "barcode.viewfinder").font(.title2)
            }
            Button { showingManualBarcode.toggle() } label: {
                Image(systemName: "keyboard").font(.title2)
            }
        }
    }

    private var historyResultsSection: some View {
        Group {
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
        }
    }

    private var manualBarcodeSection: some View {
        Group {
            if showingManualBarcode {
                HStack {
                    TextField("Skriv inn strekkode", text: $manualBarcode)
                        .keyboardType(.numberPad)
                    Button("Søk") { handleBarcode(manualBarcode) }
                        .disabled(manualBarcode.isEmpty)
                }
            }
        }
    }

    private var foodInfoSection: some View {
        Section(header: Text("Matinformasjon")) {
            TextField("Matnavn", text: $name)
        }
    }

    private var portionSection: some View {
        Section(header: Text("Måleenhet og mengde")) {
            Picker("Velg måleenhet", selection: $portionMode) {
                ForEach(PortionMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Text(portionMode == .gram ? "Antall gram" : "Antall porsjoner")
                Spacer()
                TextField("Mengde", value: $multiplier, format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 100)
            }

            if portionMode == .portion, portionSizePerServing > 0 {
                HStack {
                    Text("Porsjonsstørrelse")
                    Spacer()
                    Text("\(portionSizePerServing, specifier: "%.0f") g per porsjon")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var nutrientsSection: some View {
        Group {
            if !nutrients.isEmpty {
                Section(header: Text("Næringsinnhold")) {
                    ForEach(nutrients) { nutrient in
                        HStack {
                            Text(nutrient.name)
                            Spacer()
                            Text(formattedAmount(for: nutrient))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Beregning av næringsverdier

    private func formattedAmount(for nutrient: Nutrient) -> String {
        let value: Double
        switch portionMode {
        case .gram:
            value = nutrient.valuePerGram * multiplier
        case .portion:
            if let perServing = nutrient.valuePerServing, perServing > 0 {
                value = perServing * multiplier
            } else if portionSizePerServing > 0 {
                value = nutrient.valuePerGram * portionSizePerServing * multiplier
            } else {
                value = nutrient.valuePerGram * multiplier
            }
        }
        if nutrient.unit.lowercased() == "kcal" {
            return "\(value.rounded()) \(nutrient.unit)"
        } else {
            return String(format: "%.2f %@", value, nutrient.unit)
        }
    }

    private func currentCaloriesTotal() -> Double {
        guard let energy = nutrients.first(where: { $0.key == "energy" }) else { return 0 }
        switch portionMode {
        case .gram:
            return energy.valuePerGram * multiplier
        case .portion:
            if let perServing = energy.valuePerServing, perServing > 0 {
                return perServing * multiplier
            } else if portionSizePerServing > 0 {
                return energy.valuePerGram * portionSizePerServing * multiplier
            } else {
                return energy.valuePerGram * multiplier
            }
        }
    }

    // MARK: - Core Data-søk

    private func filterFoods() {
        let request: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
        request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", searchText)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FoodItem.name, ascending: true)]
        filteredFoods = (try? moc.fetch(request)) ?? []
    }

    // MARK: - Strekkodehåndtering

    private func handleBarcode(_ code: String) {
        currentBarcode = code
        let request: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
        request.predicate = NSPredicate(format: "barcode == %@", code)
        if let match = try? moc.fetch(request).first {
            name = match.name ?? ""
            calories = Double(match.calories)
            fetchFoodInfo(for: code)
            return
        }
        fetchFoodInfo(for: code)
    }

    // MARK: - Hent data fra Open Food Facts

    private func fetchFoodInfo(for barcode: String) {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(barcode).json") else { return }
        isLoading = true
        errorMessage = nil

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async { isLoading = false }

            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    errorMessage = "Kunne ikke hente data."
                    showingErrorAlert = true
                }
                return
            }

            guard
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let product = json["product"] as? [String: Any]
            else {
                DispatchQueue.main.async {
                    errorMessage = "Ugyldig svar fra API."
                    showingErrorAlert = true
                }
                return
            }

            let rawName = product["product_name"] as? String ?? ""
            let trimmedName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            let fetchedName = trimmedName.isEmpty ? "Ukjent produkt" : trimmedName

            let nutriments = product["nutriments"] as? [String: Any] ?? [:]
            let servingSizeStr = (product["serving_size"] as? String) ?? ""
            let servingSizeNumeric = Double(servingSizeStr
                .components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted)
                .joined()) ?? 0
            let servingQuantity = (product["serving_quantity"] as? Double) ?? 0
            let computedPortionSize = servingQuantity > 0 ? servingQuantity : servingSizeNumeric

            func val(_ key: String) -> Double {
                if let d = nutriments[key] as? Double { return d }
                if let s = nutriments[key] as? String, let d = Double(s) { return d }
                return 0
            }

            // Bryt opp verdier for kompilatorens skyld
            let energy100g = val("energy-kcal_100g")
            let energyServing = val("energy-kcal_serving")
            let carbs100g = val("carbohydrates_100g")
            let carbsServing = val("carbohydrates_serving")
            let fiber100g = val("fiber_100g")
            let fiberServing = val("fiber_serving")
            let sugar100g = val("sugars_100g")
            let sugarServing = val("sugars_serving")
            let protein100g = val("proteins_100g")
            let proteinServing = val("proteins_serving")
            let fat100g = val("fat_100g")
            let fatServing = val("fat_serving")
            let satFat100g = val("saturated-fat_100g")
            let satFatServing = val("saturated-fat_serving")
            let calcium100g = val("calcium_100g")
            let calciumServing = val("calcium_serving")

            let unsatFat100g = max(0, fat100g - satFat100g)
            let unsatFatServing = fatServing > 0 && satFatServing > 0 ? fatServing - satFatServing : nil

            let temp: [Nutrient] = [
                Nutrient(key: "energy", name: "Kalorier", unit: "kcal", valuePerGram: energy100g / 100, valuePerServing: energyServing),
                Nutrient(key: "carbs", name: "Karbohydrater", unit: "g", valuePerGram: carbs100g / 100, valuePerServing: carbsServing),
                Nutrient(key: "fiber", name: "Fiber", unit: "g", valuePerGram: fiber100g / 100, valuePerServing: fiberServing),
                Nutrient(key: "sugar", name: "Sukker", unit: "g", valuePerGram: sugar100g / 100, valuePerServing: sugarServing),
                Nutrient(key: "protein", name: "Protein", unit: "g", valuePerGram: protein100g / 100, valuePerServing: proteinServing),
                Nutrient(key: "fat", name: "Fett", unit: "g", valuePerGram: fat100g / 100, valuePerServing: fatServing),
                Nutrient(key: "sat_fat", name: "Mettet fett", unit: "g", valuePerGram: satFat100g / 100, valuePerServing: satFatServing),
                Nutrient(key: "unsat_fat", name: "Umettet fett", unit: "g", valuePerGram: unsatFat100g / 100, valuePerServing: unsatFatServing),
                Nutrient(key: "calcium", name: "Kalsium", unit: "mg", valuePerGram: calcium100g / 100, valuePerServing: calciumServing)
            ]

            DispatchQueue.main.async {
                self.name = fetchedName
                self.nutrients = temp
                self.currentBarcode = barcode
                self.portionSizePerServing = computedPortionSize
                self.calories = self.currentCaloriesTotal()
            }
        }.resume()
    }
}
