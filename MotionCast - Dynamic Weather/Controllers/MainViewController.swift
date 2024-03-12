import UIKit
import CoreLocation
import MapKit

class MainViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    public let SEGUE_IDENTIFER_TO_MAPS = "MAIN_TO_MAPS"
    public let SEGUE_IDENTIFIER_TO_WEATHER = "MAIN_TO_WEATHER"
    public let SEGUE_IDENTIFIER_TO_NEWS = "MAIN_TO_NEWS"
    public let DEFAULT_CITY_IF_CITY_IS_EMPTY = "Waterloo"
    
    var userCityInput : String? = ""
    var originatedFromHome = false
    
    var locationManager : CLLocationManager!
    @IBOutlet var mapView : MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestLocation()
        mapView.showsUserLocation = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        originatedFromHome = false
    }
    
    
    ///Instantiate a viewcontroller and goto any of the 3 bottom tabs from the input values
    @IBAction func onExploreCityButtonClicked() {
        
        let alertController = UIAlertController(title: "City", message: "", preferredStyle: .alert)
        alertController.addTextField()
        let textField = alertController.textFields!.first
        textField?.placeholder = "Hamilton"
        
        let mapsAction = UIAlertAction(title: "Directions to", style: .default) { sender in
            self.userCityInput = textField?.text
            self.originatedFromHome = true
            self.performSegue(withIdentifier: self.SEGUE_IDENTIFER_TO_MAPS, sender: sender.self)
        }
        
        let newsAction = UIAlertAction(title: "Headlines in", style: .default) { sender in
            self.userCityInput = textField?.text
            self.originatedFromHome = true
            self.performSegue(withIdentifier: self.SEGUE_IDENTIFIER_TO_NEWS, sender: sender.self)
        }
        
        let weatherAction = UIAlertAction(title: "Weather in", style: .default) { sender in
            self.userCityInput = textField?.text
            self.originatedFromHome = true
            self.performSegue(withIdentifier: self.SEGUE_IDENTIFIER_TO_WEATHER, sender: sender.self)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        
        alertController.addAction(mapsAction)
        alertController.addAction(newsAction)
        alertController.addAction(weatherAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch(segue.identifier) {
            
        case SEGUE_IDENTIFER_TO_MAPS:
            let controller = segue.destination as! MapViewController
            controller.EXTERNAL_ARGUMENT_city = getDefaultCityIfStringIsEmpty(str: userCityInput ?? "")
            controller.EXTERNAL_ARGUMENT_originatedFromHome = originatedFromHome
            
        case SEGUE_IDENTIFIER_TO_NEWS:
            let controller = segue.destination as! NewsViewController
            controller.EXTERNAL_ARGUMENT_city = getDefaultCityIfStringIsEmpty(str: userCityInput ?? "")
            controller.EXTERNAL_ARGUMENT_originatedFromHome = originatedFromHome
            
        case SEGUE_IDENTIFIER_TO_WEATHER:
            let controller = segue.destination as! WeatherViewController
            controller.EXTERNAL_ARGUMENT_city = getDefaultCityIfStringIsEmpty(str: userCityInput ?? "")
            controller.EXTERNAL_ARGUMENT_originatedFromHome = originatedFromHome
            
        default:
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentUserLocationCoords = locations.last?.coordinate
        
        
        
        if(currentUserLocationCoords != nil) {
            renderMap(originCoords: currentUserLocationCoords!)
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
    
    ///Renders map where provided coordinates are origin
    func renderMap(originCoords : CLLocationCoordinate2D) {
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: originCoords, span: span)
        self.mapView.setRegion(region, animated: true)
    }
    
    func getDefaultCityIfStringIsEmpty(str : String) -> String {
        if(str.hasValidValue()) { return str }
        else { return DEFAULT_CITY_IF_CITY_IS_EMPTY }
    }
}

