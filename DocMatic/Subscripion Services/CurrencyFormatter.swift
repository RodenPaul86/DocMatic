//
//  CurrencyFormatter.swift
//  DocMatic
//
//  Created by Paul  on 6/29/25.
//

import Foundation
import CoreLocation
import Combine

@MainActor
class CurrencyFormatter: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currencyCode: String = "USD" // default fallback
    @Published var convertedAmount: String = ""
    
    // Static exchange rates relative to USD
    private let exchangeRates: [String: Double] = [
        "USD": 1.0,
        "EUR": 0.93,
        "GBP": 0.79,
        "JPY": 157.12,
        "CAD": 1.37,
        "AUD": 1.52,
        "INR": 83.26
    ]
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        fetchCurrencyCode(from: location)
        locationManager.stopUpdatingLocation()
    }
    
    private func fetchCurrencyCode(from location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            if let countryCode = placemarks?.first?.isoCountryCode {
                let localeID = Locale.identifier(fromComponents: [NSLocale.Key.countryCode.rawValue: countryCode])
                let locale = Locale(identifier: localeID)
                if let currency = locale.currency?.identifier {
                    self.currencyCode = currency
                }
            }
        }
    }
    
    func format(_ value: Double) -> String {
        let rate = exchangeRates[currencyCode] ?? 1.0
        let convertedValue = value * rate
        
        return convertedValue.formatted(
            .currency(code: currencyCode)
            .notation(.compactName)
            .precision(.fractionLength(0...2))
        )
    }
}
