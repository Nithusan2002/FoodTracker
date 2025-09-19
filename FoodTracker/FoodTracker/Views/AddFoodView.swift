import SwiftUI
import CoreData

enum PortionMode: String, CaseIterable {
    case gram = "Gram"
    case portion = "Porsjon"
}

struct AddFoodView: View {
    @ObservedObject var viewModel: FoodViewModel
    @Environment(\.dismiss) private var dismiss

    // Felter
    @State private var name = ""
    @State private var calories = ""
    @State private var carbs = ""
    @State private var protein = ""
    @State private var fat = ""
    @State private var selectedMealType: String

    // Strekkode
    @State private var currentBarcode: String?
    @State private var showingScanner = false
    @State private var showingManualBarcode = false
    @State private var manualBarcode = ""

    // Porsjon
    @State private var portionMode: PortionMode = .gram
    @State private var multiplier: Double = 100 // gram som standard
    @State private var portionSizePerServing: Double = 0

    // Status
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingErrorAlert = false

    // API-data for beregning
    @State private var kcalPer100g: Double = 0
    @State private var carbsPer100g: Double = 0
    @State private var proteinPer100g: Double = 0
    @State private var fatPer100g: Double = 0
    @State private var kcalPerPortion: Double = 0
    @State private var carbsPerPortion: Double = 0
    @State private var proteinPerPortion: Double = 0
    @State private var fatPerPortion: Double = 0

    init(viewModel: FoodViewModel, preselectedMealType: String = "frokost") {
        self.viewModel = viewModel
        _selectedMealType = State(initialValue: preselectedMealType)
    }

    var body: some View {
        NavigationView {
            Form {
                // Måltidstype
                Section(header: Text("Måltidstype")) {
                    Picker("Velg måltid", selection: $selectedMealType) {
                        Text("Frokost").tag("frokost")
                        Text("Lunsj").tag("lunsj")
                        Text("Middag").tag("middag")
                        Text("Snacks").tag("snacks")
                    }
                    .pickerStyle(.menu)
                }
                // Matinformasjon
                Section(header: Text("Matinformasjon")) {
                    TextField("Navn", text: $name)
                    TextField("Kalorier", text: $calories)
                        .keyboardType(.numberPad)
                }

                // Makroer
                Section(header: Text("Makronæringsstoffer")) {
                    TextField("Karbohydrater (g)", text: $carbs)
                        .keyboardType(.decimalPad)
                    TextField("Proteiner (g)", text: $protein)
                        .keyboardType(.decimalPad)
                    TextField("Fett (g)", text: $fat)
                        .keyboardType(.decimalPad)
                }

                // Mengde / porsjon
                Section(header: Text("Mengde")) {
                    Picker("Enhet", selection: $portionMode) {
                        ForEach(PortionMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    if portionMode == .gram {
                        Stepper(value: $multiplier, in: 1...1000, step: 1) {
                            Text("\(Int(multiplier)) g")
                        }
                    } else {
                        Stepper(value: $multiplier, in: 0.5...10, step: 0.5) {
                            Text("\(multiplier, specifier: "%.1f") porsjoner")
                        }
                        if portionSizePerServing > 0 {
                            Text("1 porsjon = \(portionSizePerServing, specifier: "%.0f") g")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onChange(of: multiplier) {
                    recalcValues()
                }
                .onChange(of: portionMode) {
                    recalcValues()
                }

                // Strekkode
                Section(header: Text("Strekkode")) {
                    if let code = currentBarcode {
                        Text("Strekkode: \(code)")
                    }
                    Button("Skann strekkode") {
                        showingScanner = true
                    }
                    Button("Skriv inn strekkode manuelt") {
                        showingManualBarcode = true
                    }
                }

                if isLoading {
                    ProgressView("Henter produktinfo…")
                }
            }
            .navigationTitle("Legg til mat")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lagre") {
                        viewModel.addFood(
                            name: name,
                            calories: Int(calories) ?? 0,
                            carbs: Double(carbs) ?? 0,
                            protein: Double(protein) ?? 0,
                            fat: Double(fat) ?? 0,
                            barcode: currentBarcode,
                            mealType: selectedMealType
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty || calories.isEmpty)
                }
            }
            // Skanner
            .sheet(isPresented: $showingScanner) {
                BarcodeScannerView { code in
                    currentBarcode = code
                    showingScanner = false
                    handleBarcode(code)
                }
            }
            // Manuell inntasting
            .alert("Skriv inn strekkode", isPresented: $showingManualBarcode) {
                TextField("Strekkode", text: $manualBarcode)
                    .keyboardType(.numberPad)
                Button("OK") {
                    currentBarcode = manualBarcode
                    handleBarcode(manualBarcode)
                }
                Button("Avbryt", role: .cancel) { }
            }
            // Feilmelding
            .alert("Feil", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Ukjent feil")
            }
        }
    }
    // MARK: - API-oppslag
    private func handleBarcode(_ code: String) {
        guard !code.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(code).json"
        guard let url = URL(string: urlString) else {
            isLoading = false
            errorMessage = "Ugyldig URL"
            showingErrorAlert = true
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                    return
                }
                guard let data = data else { return }
                do {
                    let result = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
                    if let product = result.product {
                        name = product.product_name ?? ""

                        // Per 100g
                        kcalPer100g = product.nutriments?.energyKcal100g ?? 0
                        carbsPer100g = product.nutriments?.carbohydrates100g ?? 0
                        proteinPer100g = product.nutriments?.proteins100g ?? 0
                        fatPer100g = product.nutriments?.fat100g ?? 0

                        // Per porsjon
                        kcalPerPortion = product.nutriments?.energyKcalServing ?? 0
                        carbsPerPortion = product.nutriments?.carbohydratesServing ?? 0
                        proteinPerPortion = product.nutriments?.proteinsServing ?? 0
                        fatPerPortion = product.nutriments?.fatServing ?? 0

                        // Porsjonsstørrelse i gram
                        portionSizePerServing = product.serving_size_g ?? 0

                        recalcValues()
                    } else {
                        errorMessage = "Fant ikke produktinfo"
                        showingErrorAlert = true
                    }
                } catch {
                    errorMessage = "Kunne ikke lese produktdata"
                    showingErrorAlert = true
                }
            }
        }.resume()
    }

    // MARK: - Beregning
    private func recalcValues() {
        if portionMode == .gram {
            calories = String(format: "%.0f", kcalPer100g * (multiplier / 100))
            carbs = String(format: "%.1f", carbsPer100g * (multiplier / 100))
            protein = String(format: "%.1f", proteinPer100g * (multiplier / 100))
            fat = String(format: "%.1f", fatPer100g * (multiplier / 100))
        } else {
            calories = String(format: "%.0f", kcalPerPortion * multiplier)
            carbs = String(format: "%.1f", carbsPerPortion * multiplier)
            protein = String(format: "%.1f", proteinPerPortion * multiplier)
            fat = String(format: "%.1f", fatPerPortion * multiplier)
        }
    }
}

// MARK: - API-modeller
struct OpenFoodFactsResponse: Codable {
    let product: Product?
}

struct Product: Codable {
    let product_name: String?
    let nutriments: Nutriments?
    let serving_size_g: Double?
}

struct Nutriments: Codable {
    let energyKcal100g: Double?
    let carbohydrates100g: Double?
    let proteins100g: Double?
    let fat100g: Double?
    let energyKcalServing: Double?
    let carbohydratesServing: Double?
    let proteinsServing: Double?
    let fatServing: Double?
}
