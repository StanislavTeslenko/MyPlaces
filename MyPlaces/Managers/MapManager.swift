//
//  MapManager.swift
//  MyPlaces
//
//  Created by Stanislav Teslenko on 23.11.2019.
//  Copyright © 2019 Stanislav Teslenko. All rights reserved.
//

import UIKit
import MapKit

class MapManager {
    
    let locationManager = CLLocationManager()
    
    private let regionInMeters: Double = 1000
    private var directionsArray = [MKDirections]()
    private var placeCoordinate: CLLocationCoordinate2D?
    
}


//MARK: - Методы работы с картой

extension MapManager {
   
//Проверка доступности сервисов геолокации
     func checkLocationServices(mapView: MKMapView, segueIdentifier: String, closure: () -> ()) {
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            checkLocationAutorization(mapView: mapView, segueIdentifier: segueIdentifier)
            closure()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(title: "Location Services are Disabled", message: "Please enable the services into Settings -> Privacy -> Location Services")
            }
        }
    }

//Проверка авторизации приложения для использования сервисов геолокации
     func checkLocationAutorization(mapView: MKMapView, segueIdentifier: String) {
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            if segueIdentifier == "GetAddressSegue" { showUserLocation(mapView: mapView) }
            break
        case .denied:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(title: "Location Services are Denied", message: "Please enable the services into Settings -> Privacy -> Location Services")
            }
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(title: "Location Services are Restricted", message: "Please enable the services into Settings -> Privacy -> Location Services")
            }
            break
        case .authorizedAlways:
            break
        @unknown default:
            print("New case avaliable")
        }
    }

//Фокус карты на местоположении пользователя
     func showUserLocation(mapView: MKMapView) {
        
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
//Маркер заведения
     func setupPlaceMark(place: Place, mapView: MKMapView) {
        
        guard let location = place.location else {return}
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { (placemarks, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else {return}
            
            let placemark = placemarks.first
            
            let annotation = MKPointAnnotation()
            annotation.title = place.name
            annotation.subtitle = place.type
            
            guard let placemarkLocation = placemark?.location else {return}
            
            annotation.coordinate = placemarkLocation.coordinate
            self.placeCoordinate = placemarkLocation.coordinate
            
            mapView.showAnnotations([annotation], animated: true)
            mapView.selectAnnotation(annotation, animated: true)
            
        }
    }
 
//Построение маршрута от местоположения пользователя до заведения
     func getDirections(mapView: MKMapView, previousLocation: (CLLocation) -> ()) {
        
        guard let location = locationManager.location?.coordinate else {
            showAlert(title: "Error", message: "Location not found")
            return}
        
        locationManager.startUpdatingLocation()
        previousLocation(CLLocation(latitude: location.latitude, longitude: location.longitude))
       
        guard let request = createDirectionRequest(from: location) else {
            showAlert(title: "Error", message: "Destination not found")
            return
        }
        
        let directions = MKDirections(request: request)
        resetMapView(mapView: mapView, withNew: directions)
        
        directions.calculate { (response, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let response = response else {
                self.showAlert(title: "Error", message: "Direction is unavaliable")
                return
            }
            
            for route in response.routes {
                mapView.addOverlay(route.polyline)
                mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                
                let distance = String(format: "%.1f", route.distance / 1000)
                let timeInterval = route.expectedTravelTime
                print("Distance: - \(distance)")
                print("Time: - \(timeInterval)")
            }
        }
    }
    
//Настройка запроса для расчета маршрута
     func createDirectionRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        
        guard let destinationCoordinate = placeCoordinate else {return nil}
        
        let destinationLocation = MKPlacemark(coordinate: destinationCoordinate)
        let startingLocation = MKPlacemark(coordinate: coordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destinationLocation)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        return request
        
    }
  
//Изменение зоны отображения карты при перемещении пользователя
     func startTrackingUserLocation(for mapView: MKMapView, and location: CLLocation? , closure: (_ currentLocation: CLLocation) -> ()) {
        
        guard let location = location else {return}
        let center = getCenterLocation(for: mapView)
        guard center.distance(from: location) > 50 else {return}
        
        closure(center)
    }
    
//Сброс всех ранее построенных маршрутов
     func resetMapView(mapView: MKMapView, withNew directions: MKDirections) {
        
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map { $0.cancel() }
        directionsArray.removeAll()
    }

//Опредение центра отображаемой карты
     func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
}

//MARK: - Вспомогательные методы

extension MapManager {
    
//Отображение Alert-a
     func showAlert(title: String, message: String) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        
        alertController.addAction(okAction)
        
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindow.Level.alert + 1
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alertController, animated: true)
    
    }
 
}

