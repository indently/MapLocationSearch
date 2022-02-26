//
//  MapModel.swift
//  MapBusiness
//
//  Created by Federico on 26/02/2022.
//

import Foundation
import MapKit

// Address Data Model
struct Address: Codable {
   let data: [Datum]
}

struct Datum: Codable {
   let latitude, longitude: Double
   let name: String?
}

// Our Pin Locations
struct Location: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

class MapAPI: ObservableObject{
   private let BASE_URL = "http://api.positionstack.com/v1/forward"
   private let API_KEY = "92d0989cebd26dea67f59db3a280d7a6"
   
   @Published var region: MKCoordinateRegion
   @Published var coordinates = []
   @Published var locations: [Location] = []
   
   
   init() {
      // Defualt Info
      self.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5))
      
      self.locations.insert(Location(name: "Pin", coordinate: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275)), at: 0)
   }
   
   // API request
   func getLocation(address: String, delta: Double) {
      let pAddress = address.replacingOccurrences(of: " ", with: "%20")
      let url_string = "\(BASE_URL)?access_key=\(API_KEY)&query=\(pAddress)"
   
      guard let url = URL(string: url_string) else {
         print("Invalid URL")
         return }
      
      URLSession.shared.dataTask(with: url) { (data, response, error) in
         guard let data = data else {
            print(error!.localizedDescription)
            return }
         
         guard let newCoordinates = try? JSONDecoder().decode(Address.self, from: data) else { return }
         
         if newCoordinates.data.isEmpty {
            print("Could not find address...")
            return
         }
         
         // Set the new data
         DispatchQueue.main.async {
            let details = newCoordinates.data[0]
            let lat = details.latitude
            let lon = details.longitude
            
            self.coordinates = [lat, lon]
            self.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lon), span: MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta))
            
            let new_location = Location(name: "\(details.name)", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
            self.locations.removeAll()
            self.locations.insert(new_location, at: 0)
            
            print("Successfully loaded location! \(details.name)")
         }
      }
      .resume()
   }
}
