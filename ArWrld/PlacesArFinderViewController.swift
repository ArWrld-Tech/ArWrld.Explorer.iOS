//
//  PlacesArFinderViewController.swift
//  ArWrld
//
//  Created by David Hodge on 12/16/17.
//  Copyright © 2017 David Hodge. All rights reserved.
//

import UIKit
import SceneKit
import MapKit
import ARCL
import CoreLocation
import FoursquareAPIClient
import SwiftyJSON

class PlacesArFinderViewController: UIViewController, MKMapViewDelegate, SceneLocationViewDelegate, CLLocationManagerDelegate {
    
    let sceneLocationView = SceneLocationView()
    var attrId:String!
    let mapView = MKMapView()
    var userAnnotation: MKPointAnnotation?
    var locationEstimateAnnotation: MKPointAnnotation?
    
    var updateUserLocationTimer: Timer?
    var showMapView: Bool = true
    
    var centerMapOnUserLocation: Bool = true
    var displayDebugging = true
    
    var infoLabel = UILabel()
    
    var updateInfoLabelTimer: Timer?
    
    var adjustNorthByTappingSidesOfScreen = false
    
    var locationManager = CLLocationManager()
    var currentLocation:CLLocation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        infoLabel.font = UIFont.systemFont(ofSize: 10)
        infoLabel.textAlignment = .left
        infoLabel.textColor = UIColor.white
        infoLabel.numberOfLines = 0
        sceneLocationView.addSubview(infoLabel)
        sceneLocationView.locationDelegate = self
        
        view.addSubview(sceneLocationView)
        
        if showMapView {
            mapView.delegate = self
            mapView.showsUserLocation = true
            mapView.alpha = 0.8
            view.addSubview(mapView)
        }
        
        setupLocationManager()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sceneLocationView.run()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        
        // Pause the view's session
        sceneLocationView.pause()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        sceneLocationView.frame = CGRect(
            x: 0,
            y: 0,
            width: self.view.frame.size.width,
            height: self.view.frame.size.height)
        
        infoLabel.frame = CGRect(x: 6, y: 0, width: self.view.frame.size.width - 12, height: 14 * 4)
        
        if showMapView {
            infoLabel.frame.origin.y = (self.view.frame.size.height / 2) - infoLabel.frame.size.height
        } else {
            infoLabel.frame.origin.y = self.view.frame.size.height - infoLabel.frame.size.height
        }
        
        mapView.frame = CGRect(
            x: 0,
            y: self.view.frame.size.height / 1.5,
            width: self.view.frame.size.width,
            height: self.view.frame.size.height / 3)
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
            let viewRegion = MKCoordinateRegionMakeWithDistance(center, 200, 200)
            mapView.setRegion(viewRegion, animated: true)
            let locNode = LocationNode.init(location: location);
            locNode.continuallyUpdatePositionAndScale = true;
            self.sceneLocationView.updatePositionAndScaleOfLocationNode(locationNode: locNode);
            self.locationManager.stopUpdatingLocation()
            self.fetchNearby();
        }else{
            print ("Location is nil?")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error")
    }
    
    func fetchNearby(){
        let client = FoursquareAPIClient(clientId: "SYWXCHI4HZKQP2M3SK3KGJCYXYS5BYIWGZSHTEAUUWRITOHK",
                                         clientSecret: "DKQVNPMJBNIU3LYZQ0BGU5HGOIQ3EYM5DMMVMPE42WXL2N23")
        let parameter: [String: String] = [
            "ll": "38.960073,-77.361477",
            "limit": "10",
            ];
        client.request(path: "venues/search", parameter: parameter) { result in
            switch result {
            case let .success(data):
                do {
                    let json = try JSON(data: data)
                    if let items = json["response"]["venues"].array {
                        for item in items {
                            let pinCoordinate = CLLocationCoordinate2D(latitude: item["location"]["lat"].double!,
                                                                       longitude: item["location"]["lng"].double!)
                            let pinLocation = CLLocation(coordinate: pinCoordinate, altitude: self.currentLocation.altitude)
                            let pinImage = UIImage(named: "marker")!
                            let pinLocationNode = LocationAnnotationNode(location: pinLocation, image: pinImage)
                            pinLocationNode.locationConfirmed = true;
                            pinLocationNode.scaleRelativeToDistance = true;
                            
                            self.sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: pinLocationNode)
                            
                            let anno = MKPointAnnotation();
                            anno.coordinate = pinCoordinate;
                            self.mapView.addAnnotation(anno);
                        }
                    }
                }catch let jsonError as NSError{
                    print(jsonError);
                }
                
            case let .failure(error):
                // Error handling
                switch error {
                case let .connectionError(connectionError):
                    print(connectionError)
                case let .responseParseError(responseParseError):
                    print(responseParseError)
                case let .apiError(apiError):
                    print(apiError.errorType)
                    print(apiError.errorDetail)
                }
            }
        }
    }
    
    @IBAction func cancelPressed() {
        self.dismiss(animated: true , completion: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    @objc func updateUserLocation() {
        if let currentLocation = sceneLocationView.currentLocation() {
            DispatchQueue.main.async {
                
                if self.userAnnotation == nil {
                    self.userAnnotation = MKPointAnnotation()
                    self.mapView.addAnnotation(self.userAnnotation!)
                }
                
                UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.allowUserInteraction, animations: {
                    self.userAnnotation?.coordinate = currentLocation.coordinate
                }, completion: nil)
                
                if self.centerMapOnUserLocation {
                    UIView.animate(withDuration: 0.45, delay: 0, options: UIViewAnimationOptions.allowUserInteraction, animations: {
                        self.mapView.setCenter(self.userAnnotation!.coordinate, animated: false)
                    }, completion: {
                        _ in
                        self.mapView.region.span = MKCoordinateSpan(latitudeDelta: 0.0005, longitudeDelta: 0.0005)
                    })
                }
                
                self.centerMapOnLocation(location: currentLocation);
            }
        }
    }
    
    let regionRadius: CLLocationDistance = 1000
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius, regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @objc func updateInfoLabel() {
        if let position = sceneLocationView.currentScenePosition() {
            infoLabel.text = "x: \(String(format: "%.2f", position.x)), y: \(String(format: "%.2f", position.y)), z: \(String(format: "%.2f", position.z))\n"
        }
        
        if let eulerAngles = sceneLocationView.currentEulerAngles() {
            infoLabel.text!.append("Euler x: \(String(format: "%.2f", eulerAngles.x)), y: \(String(format: "%.2f", eulerAngles.y)), z: \(String(format: "%.2f", eulerAngles.z))\n")
        }
        
        let date = Date()
        let comp = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
        
        if let hour = comp.hour, let minute = comp.minute, let second = comp.second, let nanosecond = comp.nanosecond {
            infoLabel.text!.append("\(String(format: "%02d", hour)):\(String(format: "%02d", minute)):\(String(format: "%02d", second)):\(String(format: "%03d", nanosecond / 1000000))")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if let touch = touches.first {
            if touch.view != nil {
                if (mapView == touch.view! ||
                    mapView.recursiveSubviews().contains(touch.view!)) {
                    centerMapOnUserLocation = false
                } else {
                    
                    let location = touch.location(in: self.view)
                    
                    if location.x <= 40 && adjustNorthByTappingSidesOfScreen {
                        print("left side of the screen")
                        sceneLocationView.moveSceneHeadingAntiClockwise()
                    } else if location.x >= view.frame.size.width - 40 && adjustNorthByTappingSidesOfScreen {
                        print("right side of the screen")
                        sceneLocationView.moveSceneHeadingClockwise()
                    } else {
                        let image = UIImage(named: "marker")!
                        let annotationNode = LocationAnnotationNode(location: nil, image: image)
                        annotationNode.scaleRelativeToDistance = true
                        sceneLocationView.addLocationNodeForCurrentPosition(locationNode: annotationNode)
                    }
                }
            }
        }
    }
    
    //MARK: MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        if let pointAnnotation = annotation as? MKPointAnnotation {
            let marker = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
            
            if pointAnnotation == self.userAnnotation {
                marker.displayPriority = .required
                marker.glyphImage = UIImage(named: "user")
            } else {
                marker.displayPriority = .required
                marker.markerTintColor = UIColor(hue: 0.267, saturation: 0.67, brightness: 0.77, alpha: 1.0)
                marker.glyphImage = UIImage(named: "compass")
            }
            
            return marker
        }
        
        return nil
    }
    
    func sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
                print("add scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
    }
    
    func sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {

    }
    
    @available(iOS 11.0, *)
    func sceneLocationViewDidConfirmLocationOfNode(sceneLocationView: SceneLocationView, node: LocationNode) {
    }
    
    @available(iOS 11.0, *)
    func sceneLocationViewDidSetupSceneNode(sceneLocationView: SceneLocationView, sceneNode: SCNNode) {
        
    }
    
    @available(iOS 11.0, *)
    func sceneLocationViewDidUpdateLocationAndScaleOfLocationNode(sceneLocationView: SceneLocationView, locationNode: LocationNode) {
        guard let currentLocation = sceneLocationView.currentLocation() else{return}
        guard let nodelocation = locationNode.location else{return}
        
        let trimCurLoc = CLLocation(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
        
        let distance = trimCurLoc.distance(from: nodelocation)
        
        var scale = locationNode.scale.y
        switch distance {
        case 0.0...50.0:
            scale = scale * 1.0
            break
        case 50.01...100.0:
            scale = scale * 0.8
            break
        case 100.1...500.0:
            scale = scale * 0.6
            break
        case 500.01...1000.0:
            scale = scale * 0.4
            break
        case 1000.01...100000.0:
            scale = scale * 0.3
            break
        default:
            break
        }
        locationNode.scale =  SCNVector3(x: scale, y: scale, z: scale)
    }
}

extension UIView {
    func recursiveSubviews() -> [UIView] {
        var recursiveSubviews = self.subviews
        
        for subview in subviews {
            recursiveSubviews.append(contentsOf: subview.recursiveSubviews())
        }
        
        return recursiveSubviews
    }
}
