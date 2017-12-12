//
//  ViewController.swift
//  PokeFinder
//
//  Created by Fareen on 11/21/17.
//  Copyright © 2017 Fareen. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase

class MainVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var pokeMapView: MKMapView!
    
    let locationManager = CLLocationManager()
    var mapHasCenteredOnce = false
    var geoFire: GeoFire!
    var geoFireRef: DatabaseReference!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        pokeMapView.delegate = self
        // move the map to follow the user
        pokeMapView.userTrackingMode = MKUserTrackingMode.follow
        
        // fierbase database refrence to general database using in the app
        geoFireRef = Database.database().reference()
        geoFire = GeoFire(firebaseRef: geoFireRef)
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // when view appears give permission to user to use the app and get user's location
        locationAutStatus()
    }
    
    /* CLLocationManagerDelegate methods */
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            pokeMapView.showsUserLocation = true
        }
    }
    
    /* MKMapViewDelegate methods */
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if let loc = userLocation.location {
            if !mapHasCenteredOnce {
                centerMapOnLocation(location: loc)
                mapHasCenteredOnce = true
            }
        }
    }
    
    // set up user location's image
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView: MKAnnotationView?
        
        if annotation.isKind(of: MKUserLocation.self) {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annotationView?.image = UIImage(named: "ash")
        } else if let deqAnno = pokeMapView.dequeueReusableAnnotationView(withIdentifier: "Pokemon") {
            annotationView = deqAnno
            annotationView?.annotation = annotation
        } else {
            let annoView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Pokemon")
            
            annoView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationView = annoView
        }
        
        // customizing annotation
        if let annotationView = annotationView, let anno = annotation as? PokeAnnotation {
            let btn = UIButton()
            
            annotationView.canShowCallout = true
            annotationView.image = UIImage(named: "\(anno.pokeNumber)")
            
            btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            btn.setImage(UIImage(named: "map"), for: .normal)
            
            annotationView.rightCalloutAccessoryView = btn
        }
        
        return annotationView
    }
    
    // recentering after user change location in map by panning/swipping
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        let loc = CLLocation(latitude: pokeMapView.centerCoordinate.latitude, longitude: pokeMapView.centerCoordinate.longitude)
        
        showSightingsOnMap(location: loc)
    }
    
    // setup map after tapping on the chosen pokemon
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let anno = view.annotation as? PokeAnnotation {
            // working with apple map
            let place = MKPlacemark(coordinate: anno.coordinate)
            let destination = MKMapItem(placemark: place)
            destination.name = "Pokemon Sighting"
            
            let regionDistance: CLLocationDistance = 1000
            let regionSpan = MKCoordinateRegionMakeWithDistance(anno.coordinate, regionDistance, regionDistance)
            
            let options = [MKLaunchOptionsMapCenterKey: NSValue (mkCoordinate: regionSpan.center), MKLaunchOptionsMapSpanKey: NSValue (mkCoordinateSpan: regionSpan.span), MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving] as [String : Any]
            
            MKMapItem.openMaps(with: [destination], launchOptions: options)
        }
    }

    @IBAction func spotRandomPokemon(_ sender: UIButton) {
        let loc = CLLocation(latitude: pokeMapView.centerCoordinate.latitude, longitude: pokeMapView.centerCoordinate.longitude)
        let rand_id = arc4random_uniform(151) + 1
        
        createSighting(forLocation: loc, withPokemon: Int(rand_id))
    }
    
    /* helper methods */
    func locationAutStatus() {
        
        // just do it when app is loaded to save user's battery
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            pokeMapView.showsUserLocation = true
        } else {
            // request to use user's location
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    // center map to user's current location
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
        
        pokeMapView.setRegion(coordinateRegion, animated: true)
    }
    
    // set geo location
    func createSighting(forLocation location: CLLocation, withPokemon pokeId: Int) {
        geoFire.setLocation(location, forKey: "\(pokeId)")
    }
    
    // showing pokemons on map
    func showSightingsOnMap(location: CLLocation) {
        let circleQuery = geoFire?.query(at: location, withRadius: 2.5)
        _ = circleQuery?.observe(GFEventType.keyEntered, with: {(key, location) in
            if let key = key, let location = location {
                let anno = PokeAnnotation(coordinate: location.coordinate, pokeNumber: Int(key)!)
                
                self.pokeMapView.addAnnotation(anno)
            }
        })
    }
    
}

