//
//  MapViewController.swift
//  MyPlaces
//
//  Created by Stanislav Teslenko on 21.11.2019.
//  Copyright © 2019 Stanislav Teslenko. All rights reserved.
//

import UIKit
import MapKit
import  CoreLocation

protocol MapViewControllerDelegate {
    func getAddress (_ address: String?)
}

class MapViewController: UIViewController {

    let mapManager = MapManager()
    var mapViewControllerDelegate: MapViewControllerDelegate?
    var place = Place()
    
    let annotationIdentifier: String = "annotationIdentifier"
    var incomeSegueIdentifier = ""

    var previousLocation: CLLocation? {
        didSet {
            mapManager.startTrackingUserLocation(for: mapView, and: previousLocation) { (currentLocation) in
                self.previousLocation = currentLocation
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.mapManager.showUserLocation(mapView: self.mapView)
                }
            }
        }
    }
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapPinImage: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addressLabel.text = ""
    
        mapView.delegate = self
        
        setupMapView()

    }

    @IBAction func centerViewInUserLocation() {
        mapManager.showUserLocation(mapView: mapView)
    }
    
    @IBAction func closeButton() {
        dismiss(animated: true)
    }
    
    @IBAction func doneButtonPressed() {
        mapViewControllerDelegate?.getAddress(addressLabel.text)
        dismiss(animated: true)
    }
        
    @IBAction func goButtonPressed() {
        mapManager.getDirections(mapView: mapView) { (location) in
            self.previousLocation = location
        }
    }
    
}

//MARK: - Functions
    
extension MapViewController {
        

    private func setupMapView() {
        
        goButton.isHidden = true
        
        mapManager.checkLocationServices(mapView: mapView, segueIdentifier: incomeSegueIdentifier) {
            mapManager.locationManager.delegate = self
        }
   
        if incomeSegueIdentifier == "ShowMapSegue" {
            mapManager.setupPlaceMark(place: place, mapView: mapView)
            mapPinImage.isHidden = true
            addressLabel.isHidden = true
            doneButton.isHidden = true
            goButton.isHidden = false

        }
    }

}

//MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !(annotation is MKUserLocation) else {return nil}
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MKPinAnnotationView
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.canShowCallout = true
        }
        
        if let imageData = place.imageData {
           
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            imageView.layer.cornerRadius = 10
            imageView.clipsToBounds = true
            imageView.image = UIImage(data: imageData)
            
            annotationView?.rightCalloutAccessoryView = imageView
        }
     
        return annotationView
        
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        let center = mapManager.getCenterLocation(for: mapView)
        let geocoder = CLGeocoder()
        
        if incomeSegueIdentifier == "ShowMapSegue" && previousLocation != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.mapManager.showUserLocation(mapView: self.mapView)
            }
        }
        
        geocoder.cancelGeocode()
        
        geocoder.reverseGeocodeLocation(center) { (placemarks, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else {return}
            
            let placemark = placemarks.first
            let streetName = placemark?.thoroughfare
            let buildNumber = placemark?.subThoroughfare
            
            DispatchQueue.main.async {
                
                if streetName != nil && buildNumber != nil {
                self.addressLabel.text = "\(streetName!), \(buildNumber!)"
                } else if streetName != nil {
                 self.addressLabel.text = "\(streetName!)"
                } else {
                 self.addressLabel.text = ""
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        
        return renderer
    }
}

//MARK: - CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        mapManager.checkLocationAutorization(mapView: mapView, segueIdentifier: incomeSegueIdentifier)
    }
 

   
}
