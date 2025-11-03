import SwiftUI
import CoreData

struct SettingsView: View {
    // MARK: - Profil
    @AppStorage("sex") private var sex: String = "mann"   // "mann" | "kvinne"
    @AppStorage("age") private var age: Int = 22
    @AppStorage("heightCm") private var heightCm: Double = 191
    @AppStorage("weightKg") private var weightKg: Double = 96.2

    // MARK: - Aktivitet og mål
    @AppStorage("activity") private var activity: String = "moderat"
    // "stillesittende","lett","moderat","høy","ekstrem"

    @AppStorage("goalChoice") private var goalChoice: String = "vedlikehold"
    // "vedlikehold","ned_0_25","ned_0_5","opp_0_25","opp_0_5"

    // MARK: - Makrofordeling (lagres som %)
    @AppStorage("carbPct") private var carbPct: Double = 40
    @AppStorage("proteinPct") private var proteinPct: Double = 30
    @AppStorage("fatPct") private var fatPct: Double = 30

    // MARK: - Utregninger
    private var bmr: Double {
        // Mifflin–St Jeor
        // Mann: 10w + 6.25h − 5a + 5 ; Kvinne: ... − 161
        let base = 10*weightKg + 6.25*heightCm - 5*Double(age)
        return sex == "mann" ? base + 5 : base - 161
    }
    private var activityFactor: Double {
        switch activity {
        case "stillesittende": return 1.2
        case "lett":           return 1.375
        case "moderat":        return 1.55
        case "høy":            return 1.725
        case "ekstrem":        return 1.9
        default:               return 1.55
        }
    }
    private var tdee: Double { bmr * activityFactor }

    // ± kcal/dag basert på ca. 0.25/0.5 kg pr uke
    private var calorieAdjustment: Double {
        switch goalChoice {
        case "vedlikehold": return 0
        case "ned_0_25":    return -275
        case "ned_0_5":     return -550
        case "opp_0_25":    return  275
        case "opp_0_5":     return  550
        default:            return 0
        }
    }

    @AppStorage("dailyCalorieGoal") private var dailyCalorieGoal: Double = 2200
    private var recommendedCalories: Double {
        max(1200, round(tdee + calorieAdjustment)) // enkel sikkerhetsmargin
    }

    // Makro-mål (gram) fra prosent + kcal (karbo/protein 4 kcal/g, fett 9 kcal/g)
    private var carbGoalG: Int    { Int((recommendedCalories * (carbPct/100)) / 4.0) }
    private var proteinGoalG: Int { Int((recommendedCalories * (proteinPct/100)) / 4.0) }
    private var fatGoalG: Int     { Int((recommendedCalories * (fatPct/100)) / 9.0) }

    // MARK: - Om appen / metadata
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
    }
    private var feedbackURL: URL? {
        let subject = "Tilbakemelding FoodTracker v\(appVersion) (\(buildNumber))"
        let encoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Tilbakemelding"
        return URL(string: "mailto:din.epost@domene.no?subject=\(encoded)")
    }

    // MARK: - Miljø og state
    @Environment(\.managedObjectContext) private var moc
    @State private var showWipeAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Profil
                Section("Profil") {
                    Picker("Kjønn", selection: $sex) {
                        Text("Mann").tag("mann")
                        Text("Kvinne").tag("kvinne")
                    }
                    Stepper("Alder: \(age) år", value: $age, in: 14...100)

                    HStack {
                        Text("Høyde")
                        Spacer()
                        TextField("cm", value: $heightCm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("cm").foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Vekt")
                        Spacer()
                        TextField("kg", value: $weightKg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("kg").foregroundColor(.secondary)
                    }
                }

                // MARK: Aktivitet
                Section("Aktivitetsnivå") {
                    Picker("Aktivitet", selection: $activity) {
                        Text("Stillesittende").tag("stillesittende")
                        Text("Lett (1–3 økter/uke)").tag("lett")
                        Text("Moderat (3–5)").tag("moderat")
                        Text("Høy (6–7)").tag("høy")
                        Text("Ekstrem (fysisk jobb + trening)").tag("ekstrem")
                    }
                }

                // MARK: Mål
                Section("Mål") {
                    Picker("Vekstmål", selection: $goalChoice) {
                        Text("Vedlikehold").tag("vedlikehold")
                        Text("Ned −0,25 kg/uke").tag("ned_0_25")
                        Text("Ned −0,5 kg/uke").tag("ned_0_5")
                        Text("Opp +0,25 kg/uke").tag("opp_0_25")
                        Text("Opp +0,5 kg/uke").tag("opp_0_5")
                    }

                    Button {
                        dailyCalorieGoal = recommendedCalories
                    } label: {
                        Label("Bruk \(Int(recommendedCalories)) kcal/dag som mål", systemImage: "checkmark.circle.fill")
                    }
                }

                // MARK: Makro-fordeling
                Section("Makro-fordeling (%)") {
                    macroSliderRow(label: "Karbohydrater", value: $carbPct)
                    macroSliderRow(label: "Proteiner", value: $proteinPct)
                    macroSliderRow(label: "Fett", value: $fatPct)

                    let sum = carbPct + proteinPct + fatPct
                    if Int(sum) != 100 {
                        Text("Summen er \(Int(sum))%. Justér til 100%.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }

                    HStack { Text("Karbo-mål");   Spacer(); Text("\(carbGoalG) g") }
                    HStack { Text("Protein-mål"); Spacer(); Text("\(proteinGoalG) g") }
                    HStack { Text("Fett-mål");    Spacer(); Text("\(fatGoalG) g") }
                    Text("Beregnes fra \(Int(recommendedCalories)) kcal · 4 kcal/g (karbo/protein) · 9 kcal/g (fett)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // MARK: Beregninger
                Section("Beregninger") {
                    HStack { Text("BMR (Mifflin–St Jeor)"); Spacer(); Text("\(Int(bmr)) kcal") }
                    HStack { Text("TDEE"); Spacer(); Text("\(Int(tdee)) kcal") }
                    HStack { Text("Anbefalt daglig mål"); Spacer(); Text("\(Int(recommendedCalories)) kcal") }
                }

                // MARK: Ansvarsfraskrivelse
                Section {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                            .font(.title3)
                        Text("""
                        Beregningene i denne appen er kun ment som veiledende estimater \
                        basert på generelle formler (Mifflin–St Jeor og aktivitetsnivå). \
                        Faktiske behov kan variere betydelig mellom individer. \
                        Dette erstatter ikke råd fra lege eller ernæringsfysiolog.
                        """)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(Color.clear)

                // MARK: Om appen
                Section {
                    VStack(spacing: 10) {
                        Image("FoodTrackerLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        Text("FoodTracker")
                            .font(.headline)

                        Text("Versjon \(appVersion) · Build \(buildNumber)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)

                    if let feedbackURL {
                        Link(destination: feedbackURL) {
                            Label("Send tilbakemelding", systemImage: "envelope")
                        }
                    }
                    Link(destination: URL(string: "https://example.com")!) {
                        Label("Nettside", systemImage: "globe")
                    }
                    Link(destination: URL(string: "https://github.com/Nithusan2002/FoodTracker")!) {
                        Label("GitHub-prosjekt", systemImage: "chevron.left.slash.chevron.right")
                    }
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        Label("Personvern", systemImage: "hand.raised")
                    }
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        Label("Vilkår for bruk", systemImage: "doc.text")
                    }

                    if let shareURL = URL(string: "https://github.com/Nithusan2002/FoodTracker") {
                        ShareLink(item: shareURL) {
                            Label("Del appen", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                .headerProminence(.increased)
                .listRowBackground(Color.clear)

                // MARK: Danger zone (valgfritt)
                Section {
                    Button(role: .destructive) {
                        showWipeAlert = true
                    } label: {
                        Label("Slett alle data", systemImage: "trash")
                    }
                } footer: {
                    Text("Sletter alle registrerte matvarer permanent fra denne enheten.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Innstillinger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(Color("AppGreen"))
            .alert("Slett alle data?", isPresented: $showWipeAlert) {
                Button("Slett", role: .destructive) { wipeAllData() }
                Button("Avbryt", role: .cancel) {}
            } message: {
                Text("Denne handlingen kan ikke angres.")
            }
        }
    }

    // MARK: - Hjelpere
    private func macroSliderRow(label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack { Text(label); Spacer(); Text("\(Int(value.wrappedValue))%") }
            Slider(value: value, in: 0...100, step: 1)
        }
    }

    private func wipeAllData() {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "FoodItem")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        do {
            try moc.execute(request)
            try moc.save()
        } catch {
            print("Kunne ikke slette data: \(error)")
        }
    }
}

#Preview {
    SettingsView()
}
