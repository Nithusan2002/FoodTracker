//
//  FetchFoodInfoFromAPI.swift
//  FoodTrackerTests
//
//  Created by Nithusan Krishnasamymudali on 18/09/2025.
//

import Foundation
import Testing
@testable import FoodTracker

@Test
func fetchFoodInfoFromAPI() async throws {
    // 1. Forventet strekkode
    let barcode = "7038010068980" // YT-vanilje yoghurt

    // 2. Lag URL
    let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(barcode).json")!

    // 3. Hent data asynkront
    let (data, _) = try await URLSession.shared.data(from: url)

    // 4. Parse JSON
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let product = json?["product"] as? [String: Any]
    let name = product?["product_name"] as? String

    // 5. Sjekk at vi fikk et navn
    #expect(name != nil, "Produktnavn mangler")
    print("✅ Produktnavn: \(name ?? "ukjent")")
}
