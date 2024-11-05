//
//  ViewController.swift
//  Lab3_MonikaBhalla
//
//  Created by MONIKA BHALLA  on 2024-11-04.
//

import UIKit
import CoreLocation


class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var weatherCondition: UIImageView!
    
    @IBOutlet weak var tempratureLabel: UILabel!
    
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var weatherStatus: UILabel!
    
    @IBOutlet weak var toggleButton: UISwitch!
    
    private var isCelsius: Bool = true // Tracks temperature unit
    private let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.lightGray // Change 'red' to your desired color

        displaySampleImage()
        
        // Set up toggle button action
        toggleButton.addTarget(self, action: #selector(toggleTemperatureUnit), for: .valueChanged)
        
        // Configure location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    private func displaySampleImage() {
        let config = UIImage.SymbolConfiguration(paletteColors: [.systemYellow, .systemBlue, .systemOrange])
        weatherCondition.preferredSymbolConfiguration = config
        weatherCondition.image = UIImage(systemName: "cloud.sun.rain.fill") // Default icon
    }
    
    
    @IBAction func OnLocation(_ sender: UIButton) {
        locationManager.requestWhenInUseAuthorization()
        
        // Check the authorization status
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.startUpdatingLocation() // Start updating location only if authorized
        } else {
            print("Location access not granted")
        }
    }
    
    
    @IBAction func onSearch(_ sender: UIButton) {
        loadWeatherData(search: searchTextField.text)
        
    }
    
    @objc private func toggleTemperatureUnit() {
        isCelsius.toggle()
        if let tempText = tempratureLabel.text, let tempValue = Float(tempText.dropLast(2)) {
            let updatedTemp = isCelsius ? tempValue : (tempValue * 9/5) + 32
            let unit = isCelsius ? "°C" : "°F"
            tempratureLabel.text = String(format: "%.1f%@", updatedTemp, unit)
        }
    }
    
    private func loadWeatherData(search: String?) {
        guard let search = search else { return }
        guard let url = getURL(query: search) else {
            print("Could not create URL")
            return
        }
        
        fetchData(from: url)
    }
    
    private func loadWeatherData(lat: Double, lon: Double) {
        guard let url = getURL(lat: lat, lon: lon) else {
            print("Could not create URL")
            return
        }
        
        fetchData(from: url)
    }
    
    private func fetchData(from url: URL) {
        let session = URLSession.shared
        let dataTask = session.dataTask(with: url) { data, response, error in
            guard error == nil, let data = data else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let weatherResponse = self.parseJson(data: data) {
                DispatchQueue.main.async {
                    self.updateUI(with: weatherResponse)
                }
            }
        }
        dataTask.resume()
    }
    
    private func updateUI(with weatherResponse: WeatherResponse) {
        locationLabel.text = weatherResponse.location.name
        let temp = isCelsius ? weatherResponse.current.temp_c : (weatherResponse.current.temp_c * 9/5) + 32
        let unit = isCelsius ? "°C" : "°F"
        tempratureLabel.text = String(format: "%.1f%@", temp, unit)
        weatherStatus.text = weatherResponse.current.condition.text

        // Check if it's day or night
        let isDay = isDayTime()
        updateWeatherIcon(for: weatherResponse.current.condition.code, conditionText: weatherResponse.current.condition.text, isDay: isDay)
    }

    
    private func isDayTime() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 6 && hour < 18 // Assuming day time is between 6 AM and 6 PM
    }


    private func updateWeatherIcon(for code: Int, conditionText: String, isDay: Bool) {
        let config = UIImage.SymbolConfiguration(paletteColors: [.systemYellow, .systemBlue, .systemOrange])
        weatherCondition.preferredSymbolConfiguration = config
        
        let systemImageName: String
        switch code {
        case 1000: // Sunny
            systemImageName = (conditionText.lowercased() == "sunny") ? "sun.max.fill" : (isDay ? "sun.and.horizon.fill" : "moon.fill")
        case 1003, 1006: // Partly Cloudy
            systemImageName = isDay ? "cloud.sun.bolt.fill" : "cloud.moon.bolt.fill"
        case 1009: // Cloudy
            systemImageName = isDay ? "cloud.fill" : "cloud.moon.fill"
        case 1030, 1135, 1147: // Foggy
            systemImageName = "cloud.fog.fill"
        case 1063, 1150...1189: // Rain
            systemImageName = "cloud.drizzle.fill"
        case 1192...1201: // Heavy Rain
            systemImageName = "cloud.heavyrain.fill"
        case 1210...1216: // Snow
            systemImageName = "cloud.snow.fill"
        case 1273...1276: // Thunderstorm
            systemImageName = "cloud.bolt.rain.fill"
        default:
            systemImageName = "cloud.fill" // Default icon
        }

        weatherCondition.image = UIImage(systemName: systemImageName)
    }


    private func getURL(query: String) -> URL? {
        let baseURL = "https://api.weatherapi.com/v1/"
        let currentEndpoint = "current.json"
        let apiKey = "dab2604109964c28804204346240411"
        guard let urlString = "\(baseURL)\(currentEndpoint)?key=\(apiKey)&q=\(query)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: urlString) else { return nil }
        return url
    }
    
    private func getURL(lat: Double, lon: Double) -> URL? {
        let baseURL = "https://api.weatherapi.com/v1/"
        let currentEndpoint = "current.json"
        let apiKey = "dab2604109964c28804204346240411"
        let urlString = "\(baseURL)\(currentEndpoint)?key=\(apiKey)&q=\(lat),\(lon)"
        return URL(string: urlString)
    }
    
    private func parseJson(data: Data) -> WeatherResponse? {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(WeatherResponse.self, from: data)
        } catch {
            print("Error decoding: \(error)")
            return nil
        }
    }
    
    // MARK: - CLLocationManagerDelegate Methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            locationManager.stopUpdatingLocation()
            loadWeatherData(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
        print("Current authorization status: \(CLLocationManager.authorizationStatus().rawValue)")
    }
}

struct WeatherResponse: Decodable {
    let location: Location
    let current: Weather
}

struct Location: Decodable {
    let name: String
}

struct Weather: Decodable {
    let temp_c: Float
    let condition: WeatherCondition
}

struct WeatherCondition: Decodable {
    let text: String
    let code: Int
}
