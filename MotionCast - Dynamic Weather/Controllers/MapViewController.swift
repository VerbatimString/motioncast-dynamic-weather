//
//  MapViewController.swift
//  Kashif_Kadri_FE_8866889
//
//  Created by AK on 2023-12-01.
//

import UIKit
import MapKit

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    public var EXTERNAL_ARGUMENT_city : String = "Hamilton,ON"
    public var EXTERNAL_ARGUMENT_originatedFromHome = false
    
    public enum TransportationMode : String {
        case AUTOMOBILE = "Automobile"
        case MOTORCYCLE = "Motorcycle"
        case WALK = "Walk"
    }
    
    @IBOutlet var mapView : MKMapView!
    @IBOutlet var autoMobileBtn : UIButton!
    @IBOutlet var bikeBtn : UIButton!
    @IBOutlet var walkBtn : UIButton!
    
    var locationManager : CLLocationManager!
    var lastLocation : CLLocation!
    var destinationLat : Double = -1
    var destinationLon : Double = -1
    var currentTransportationMode = TransportationMode.AUTOMOBILE
    var currentDestinationCity = ""
    var originCity = ""
    
    var currentlyLoadingCoordinates = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("External argument received: CITY - " + EXTERNAL_ARGUMENT_city)
        
        if(EXTERNAL_ARGUMENT_city.hasValidValue()) {
            currentDestinationCity = EXTERNAL_ARGUMENT_city
            locationManager = CLLocationManager()
            locationManager.delegate = self
            mapView.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            mapView.showsUserLocation = true
            locationManager.startUpdatingLocation()
            reverseGeocodeCityThenInitialize()
        } else {
         //TODO: Handle error
        }
    }
    
    /// Reinitializes the map by removing latest annotation and request location
    func reinitializeMap() {
        
        if(mapView.annotations.last != nil) {
            mapView.removeAnnotation(mapView.annotations.last!)
        }
        
        locationManager.stopUpdatingLocation()
        locationManager.requestLocation()
        locationManager.startUpdatingLocation()
        mapView.removeOverlays(mapView.overlays)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if(currentlyLoadingCoordinates) { return }
        
        lastLocation = locations.last
        updateUi(lastLocation)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        //todo: location request failed
    }
    

    /// Converts the current city string to coordinates and then updates lat/lon variables. Calls reinitialize() method after that.
    func reverseGeocodeCityThenInitialize() {
        currentlyLoadingCoordinates = true
        let geoCoder = CLGeocoder()
        
        geoCoder.geocodeAddressString(currentDestinationCity) { [self]
            (placemarks, error) in
            print("geocoder returned sum")
            if(placemarks != nil) {
                print("geocoder didnt return null")
                let location = placemarks?.first?.location
                destinationLon = (location?.coordinate.longitude)!
                destinationLat = (location?.coordinate.latitude)!
                
                print(String(destinationLat) + "," + String(destinationLon))
                currentlyLoadingCoordinates = false
                reinitializeMap()
            } else {
                print("Error occured during city fetch")
                currentlyLoadingCoordinates = false
            }
        }
    }
    
    /// Updates UI with latest CLLocation data
    /// - Parameters:
    ///     - latesttLocation: render mapview using location
    func updateUi(_ latestLocation : CLLocation) {
        
        if(destinationLat == 0 || destinationLon == 0) {
            return
        }
        
        print("Update ui called")
        
        setOriginCityNameFromCLLocation(location: latestLocation)
        
        let coordinate = latestLocation.coordinate
        let span = MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 4)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        let pin = MKPointAnnotation ()
        pin.coordinate = coordinate
        self.mapView.addAnnotation(pin)
        self.mapView.setRegion(region, animated: true)
        
        let sourceCoords = (lastLocation.coordinate)
        
        let sourcePlacemark = MKPlacemark(coordinate: sourceCoords)
        
        let destinationCoords = CLLocationCoordinate2D(
            latitude: destinationLat,
            longitude: destinationLon)
        
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoords)
    
        let sourceItem = MKMapItem(placemark: sourcePlacemark)
        
        let destinationItem = MKMapItem(placemark: destinationPlacemark)
        
        let destinationRequest = MKDirections.Request()
        
        destinationRequest.source = sourceItem
        
        destinationRequest.destination = destinationItem
        
        destinationRequest.transportType = getTransportationMode()
                
        let directions = MKDirections(request: destinationRequest)
        
        directions.calculate { [self] (response, error) in
            
            guard let response = response else {
                
                if let error = error  {
                    print("something went wrong")
                }
                
                return
                
            }
            
            let route = response.routes.last
            
            self.mapView.addOverlay(route!.polyline)
            
            self.mapView.setVisibleMapRect(route!.polyline.boundingMapRect, animated: true)
            
            let pin = MKPointAnnotation()
            
            let coordinate = CLLocationCoordinate2D (latitude: destinationLat, longitude: destinationLon)
            
            pin.coordinate = coordinate
            
            pin.title = currentDestinationCity
            
            self.mapView.addAnnotation(pin)
            
            saveHistoryEntity()
        }
    }
    
    /// Convert internal transportation type enum to one used in MapKit
    func getTransportationMode() -> MKDirectionsTransportType {
        switch(currentTransportationMode) {
        case .AUTOMOBILE : return .automobile
        case .MOTORCYCLE: return .automobile
        case .WALK: return MKDirectionsTransportType.walking
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let routeline = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        routeline.lineWidth = 2.0
        routeline.strokeColor = .black
        return routeline
    }
    
    ///Updates map span in relation to slider value
    @IBAction func onSliderValueChanged(_ sender: UISlider) {
        if(lastLocation != nil) {
            var zoom : Double = Double(sender.value / 100) * 2.5
            
            var deltaLon = zoom + 0.01
            var deltaLat = zoom + 0.01
            print("Span deltas: " + String(deltaLon) + "," + String(deltaLat))
            let span = MKCoordinateSpan(latitudeDelta: deltaLat, longitudeDelta: deltaLon)
            let region = MKCoordinateRegion(center: lastLocation.coordinate, span: span)
            mapView.region = region
        }
    }
    
    ///indicates selection on button, updates member variable representing current transportation mode and reinitializes
    @IBAction func onWalkButtonClick () {
        deselectAllTransporationButtons()
        selectButton(mode: .WALK)
        currentTransportationMode = .WALK
        reinitializeMap()
    }
    
    //updates member variable representing current transportation mode and reinitializes
    @IBAction func onBikeButtonClick() {
        deselectAllTransporationButtons()
        selectButton(mode: .MOTORCYCLE)
        currentTransportationMode = .MOTORCYCLE
        locationManager.requestLocation()
        reinitializeMap()
    }
    
    ///indicates selection on button, updates member variable representing current transportation mode and reinitializes
    @IBAction func onAutoMobileButtonClick() {
        deselectAllTransporationButtons()
        selectButton(mode: .AUTOMOBILE)
        currentTransportationMode = .AUTOMOBILE
        locationManager.requestLocation()
    }
    
    ///Indicares button selection to user by changing background color
    func selectButton(mode : TransportationMode) {
        var selectionColor = UIColor(cgColor: CGColor(red: 34/255, green: 146/255, blue: 164/255, alpha: 1))
        switch(mode) {
        case .AUTOMOBILE: autoMobileBtn.backgroundColor = selectionColor
        case .MOTORCYCLE: bikeBtn.backgroundColor = selectionColor
        case .WALK: walkBtn.backgroundColor = selectionColor
        }
    }
    
    ///Indicare deselection to all  transportation mode buttons
    func deselectAllTransporationButtons () {
        var transparentColor = UIColor(cgColor: CGColor(red: 0, green: 0, blue: 0, alpha: 0))
        walkBtn.backgroundColor = transparentColor
        autoMobileBtn.backgroundColor = transparentColor
        bikeBtn.backgroundColor = transparentColor
    }
    
    ///Instantiates appropriate AlertController and reinitializes location
    @IBAction func onRerouteButtonClick() {
        var alertController = UIAlertController(title: "Destination", message: "", preferredStyle: .alert)
        alertController.addTextField()
        var textField = alertController.textFields?.first
        textField?.placeholder = EXTERNAL_ARGUMENT_city
        var changeCityAction = UIAlertAction(title: "Update", style: .default) { UIAlertAction in
            var cityText = textField?.text
            
            if(!(cityText.hasValidValue())) {
                return
            }
            
            self.EXTERNAL_ARGUMENT_originatedFromHome = false
            self.currentDestinationCity = cityText!
            self.reverseGeocodeCityThenInitialize()
        }
        
        var cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        
        alertController.addAction(changeCityAction)
        alertController.addAction(cancelAction)
        present(alertController, animated:true)
    }
    
    
    //Updates the origin city name variable based on CLLocation object
    func setOriginCityNameFromCLLocation(location: CLLocation) {
        let geoCoder = CLGeocoder()
        // Perform reverse geocoding
        geoCoder.reverseGeocodeLocation(location) { [self] placemarks, error in
            guard let placemark = placemarks?.first else {
                // Handle error or default value if needed
                originCity = "Unknown"
                return
            }
            
            originCity = placemark.locality ?? "Unknown"
        }
    }
    
    //Adds the current history object to persistance
    func saveHistoryEntity() {
        var historyEntity = HistoryEntity(context: CoreDataUtils.databaseContextLayer)
        historyEntity.interactionName = TabNames.MAPS.rawValue
        historyEntity.originTabName = EXTERNAL_ARGUMENT_originatedFromHome ? TabNames.MAIN.rawValue : TabNames.MAPS.rawValue
        historyEntity.interactionTime = Date.now
        var locationCoords = LocationCoordinatesEntity(context: CoreDataUtils.databaseContextLayer)
        locationCoords.cityName = currentDestinationCity
        historyEntity.locationCoordsEntity = locationCoords
        var mapsEntity = MapEntity(context: CoreDataUtils.databaseContextLayer)
        mapsEntity.travelMode = currentTransportationMode.rawValue
        mapsEntity.destinationCity = currentDestinationCity
        mapsEntity.originCity = originCity
        historyEntity.mapEntity = mapsEntity
        CoreDataUtils.save()
    }
}
