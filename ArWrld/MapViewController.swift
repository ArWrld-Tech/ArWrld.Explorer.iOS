//
//  MapViewController.swift
//  ArWrld
//
//  Created by David Hodge on 1/30/18.
//  Copyright © 2018 David Hodge. All rights reserved.
//

import Mapbox
import CoreLocation

class MyCustomPointAnnotation: MGLPointAnnotation {
    var willUseImage: Bool = false
}

class MapViewController: UIViewController, MGLMapViewDelegate, CLLocationManagerDelegate {
    
    var mapView: MGLMapView!
    var label: UILabel!
    var locationManager = CLLocationManager()
    var currentLocation:CLLocation!
    
    var coordinateArray: [CLLocationCoordinate2D] = []
    
    let kEarthRadius = 6378137.0
    
    var calcArea = 0.0;
    var calcCost = 0.0;
    
    var perSqM = 0.1;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView = MGLMapView(frame: self.view.bounds,  styleURL: URL(string: "mapbox://styles/arwrld/cjcye9ekk1zoo2slsafcfyei5"))
        self.mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(self.mapView)
        self.mapView.delegate = self
        
        self.label = UILabel(frame: CGRect(x: 0, y: 15, width: 200, height: 21))
        self.label.center = CGPoint(x: 30, y: 120)
        self.label.textAlignment = .right
        self.label.text = "0.0"
        self.label.textColor = .white;
        self.label.backgroundColor = .black;
        self.label.layer.cornerRadius = 5.0
        self.label.layer.masksToBounds = true
        self.label.font = self.label.font.withSize(9)
        self.view.addSubview(self.label)
        
        let allAnnotations = self.mapView.annotations
        if allAnnotations != nil{
            self.mapView.removeAnnotations(allAnnotations!)
        }
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(tap:)))
        for recognizer in mapView.gestureRecognizers! where recognizer is UITapGestureRecognizer {
            singleTap.require(toFail: recognizer)
        }
        mapView.addGestureRecognizer(singleTap)
        
        setupLocationManager();
    }
    
    func setupLocationManager(){
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        self.locationManager.startUpdatingLocation()
    }
    
    // Below method will provide you current location.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if currentLocation == nil {
            currentLocation = locations.last
            locationManager.stopMonitoringSignificantLocationChanges()
            var locationValue:CLLocationCoordinate2D = manager.location!.coordinate
            
            print ("Got Location")
            let location = locations.first
            let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
            //        mapView.setCenter(center, zoomLevel: 14, animated: true)
            let camera = MGLMapCamera(lookingAtCenter: center, fromDistance: 3500, pitch: 15, heading: (location?.course)!)
            mapView.setCamera(camera, withDuration: 2, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
            
            self.locationManager.stopUpdatingLocation()
        }else{
            print ("Location is nil?")
        }
    }
    
    // Below Mehtod will print error if not able to update location.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error")
    }
    
    @objc func handleSingleTap(tap: UITapGestureRecognizer) {
        // Convert tap location (CGPoint)
        // to geographic coordinate (CLLocationCoordinate2D).
        let tapCoordinate: CLLocationCoordinate2D = mapView.convert(tap.location(in: mapView), toCoordinateFrom: mapView)
        print("You tapped at: \(tapCoordinate.latitude), \(tapCoordinate.longitude)")
        self.coordinateArray.append(tapCoordinate);
        
        // Add a polyline with the new coordinates.
        let polyline = MGLPolyline(coordinates: self.coordinateArray, count: UInt(self.coordinateArray.count))
        mapView.addAnnotation(polyline)
        
        let hello = MGLPointAnnotation()
        hello.coordinate = CLLocationCoordinate2D(latitude: tapCoordinate.latitude, longitude: tapCoordinate.longitude);
        hello.title = "Point"
        self.mapView.addAnnotation(hello)
        
        if(self.coordinateArray.count > 2){
            self.calcArea = area();
        }
        self.calcCost = (self.calcArea * self.perSqM);
        self.label.text = String(format: "%.02f", self.calcCost)
    }
    
    // Use the default marker. See also: our view annotation or custom marker examples.
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        
        if let castAnnotation = annotation as? MyCustomPointAnnotation {
            if (castAnnotation.willUseImage) {
                return nil;
            }
        }
        
        // Assign a reuse identifier to be used by both of the annotation views, taking advantage of their similarities.
        let reuseIdentifier = "reusableDotView"
        
        // For better performance, always try to reuse existing annotations.
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        // If there’s no reusable annotation view available, initialize a new one.
        if annotationView == nil {
            annotationView = MGLAnnotationView(reuseIdentifier: reuseIdentifier)
            annotationView?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            annotationView?.layer.cornerRadius = (annotationView?.frame.size.width)! / 2
            annotationView?.layer.borderWidth = 4.0
            annotationView?.layer.borderColor = UIColor.black.cgColor
            annotationView!.backgroundColor = UIColor.black
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
        let camera = MGLMapCamera(lookingAtCenter: annotation.coordinate, fromDistance: 1750, pitch: self.mapView.camera.pitch, heading: self.mapView.camera.heading)
        mapView.fly(to: camera, completionHandler: nil)
    }
    
    // Allow callout view to appear when an annotation is tapped.
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    // This delegate method is where you tell the map to load an image for a specific annotation based on the willUseImage property of the custom subclass.
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        
        if let castAnnotation = annotation as? MyCustomPointAnnotation {
            if (!castAnnotation.willUseImage) {
                return nil;
            }
        }
        
        // For better performance, always try to reuse existing annotations.
        var annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: "marker")
        
        // If there is no reusable annotation image available, initialize a new one.
        if(annotationImage == nil) {
            annotationImage = MGLAnnotationImage(image: UIImage(named: "marker")!, reuseIdentifier: "marker")
        }
        
        return annotationImage
    }
    
    func mapView(_ mapView: MGLMapView, tapOnCalloutFor annotation: MGLAnnotation) {
        print("tap on callout")
        print(annotation.subtitle);
    }
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        
        // Access the Mapbox Streets source and use it to create a `MGLFillExtrusionStyleLayer`. The source identifier is `composite`. Use the `sources` property on a style to verify source identifiers.
        if let source = style.source(withIdentifier: "composite") {
            let layer = MGLFillExtrusionStyleLayer(identifier: "buildings", source: source)
            layer.sourceLayerIdentifier = "building"
            
            // Filter out buildings that should not extrude.
            layer.predicate = NSPredicate(format: "extrude == 'true' AND height >= 0")
            
            // Set the fill extrusion height to the value for the building height attribute.
            layer.fillExtrusionHeight = MGLStyleValue(interpolationMode: .identity, sourceStops: nil, attributeName: "height", options: nil)
            layer.fillExtrusionBase = MGLStyleValue(interpolationMode: .identity, sourceStops: nil, attributeName: "min_height", options: nil)
            layer.fillExtrusionOpacity = MGLStyleValue(rawValue: 0.75)
            layer.fillExtrusionColor = MGLStyleValue(rawValue: .darkGray)
            
            // Insert the fill extrusion layer below a POI label layer. If you aren’t sure what the layer is called, you can view the style in Mapbox Studio or iterate over the style’s layers property, printing out each layer’s identifier.
            if let symbolLayer = style.layer(withIdentifier: "poi-scalerank3") {
                style.insertLayer(layer, below: symbolLayer)
            } else {
                style.addLayer(layer)
            }
        }
        
        self.mapView.showsUserLocation = true
    }
    
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.characters.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    func degreesToRadians(_ radius: Double) -> Double {
        return radius * .pi / 180.0
    }
    
    func area() -> Double {
        var area: Double = 0
        
        var coords = self.coordinateArray
        coords.append(coords.first!)
        
        if (coords.count > 2) {
            var p1: CLLocationCoordinate2D, p2: CLLocationCoordinate2D
            for i in 0..<coords.count-1 {
                p1 = coords[i]
                p2 = coords[i+1]
                area += degreesToRadians(p2.longitude - p1.longitude) * (2 + sin(degreesToRadians(p1.latitude)) + sin(degreesToRadians(p2.latitude)))
            }
            area = abs(area * kEarthRadius * kEarthRadius / 2)
        }
        
        return area
    }
}
