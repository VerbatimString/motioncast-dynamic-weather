//
//  ViewController.swift
//  Whats the Weather
//
//  Created by AK on 2023-11-22.
//

import UIKit
import CoreLocation
import Lottie
import SwiftUI

class WeatherViewController: UIViewController, CLLocationManagerDelegate {
    
    public var EXTERNAL_ARGUMENT_city : String = "Hamilton,ON"
    public var EXTERNAL_ARGUMENT_originatedFromHome = false
    
    @IBOutlet var cityLabel : UILabel!
    @IBOutlet var weatherLabel : UILabel!
    @IBOutlet var temperatureLabel : UILabel!
    @IBOutlet var humidityLabel : UILabel!
    @IBOutlet var windSpeedLabel : UILabel!
    
    let loadingAnimationName = "ANIMATION_LOADING"
    
    var locationManager : CLLocationManager!
    var latestLocationInformation : CLLocation!
    var weatherType : WeatherAPIConstants.PossibleWeather!
    var weatherView : LottieAnimationView!
    var temperatureView : LottieAnimationView!
    var humidityView : LottieAnimationView!
    var windSpeedView : LottieAnimationView!
    var reloadView : LottieAnimationView!
    var searchView : LottieAnimationView!
    var loadingView : LottieAnimationView!
    var reloadButtonClickTapGesture : UITapGestureRecognizer!
    var searchButtonClickTapGesture : UITapGestureRecognizer!
    var currentlyReloadingData = false
    
    var latitude : Double = -1
    var longitude : Double = -1
    var cityName: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("External argument received: CITY - " + EXTERNAL_ARGUMENT_city)
        hideAllViews()
        
        if(EXTERNAL_ARGUMENT_city.hasValidValue()) {
            preinitialization(city: EXTERNAL_ARGUMENT_city)
        } else {
            //TODO: Handle error
            print("User city was null.")
            return
        }
        
    }
    
    func preinitialization(city : String) {
        city.convertToCoordinates { (result) in
            
            switch result {
           
            case .success(let (coordinates, cityName)):
                if(coordinates == nil || coordinates.latitude == nil || coordinates.longitude == nil) {
                    //TODO: Handle error
                    print("Failed to reverse geocode user input.")
                    return
                }
                
                self.cityName = cityName
                self.latitude = coordinates.latitude
                self.longitude = coordinates.longitude
                self.initialize()
                
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
            
        }
    }
    
    func initialize() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        showLoadingView()
        
        reloadButtonClickTapGesture = UITapGestureRecognizer(target: self, action: #selector(onReloadButtonClicked(_ : )))
        
        reloadButtonClickTapGesture = UITapGestureRecognizer(target: self, action: #selector(onSearchButtonClicked(_ : )))
        
        hideAllViews()
        
        callWeatherApi()
    }
    
    func callWeatherApi() {
        
        var url = getUrlForWeatherCall(latitude: Float(latitude), longitude: Float(longitude))
        
        if(url == nil) {
            //TODO: Notify user about empty URL.
            return
        }
        
        startGetWeatherInfoDataTask(url: url!)
        
        print("Location received!")
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to fetch location")
    }
    
    //Constructs a URL for OpenWeather API. Please view APIConstants to modify the call
    func getUrlForWeatherCall(latitude: Float, longitude: Float) -> URL? {
        
        let baseUrlWithDataDirectory = WeatherAPIConstants.BASE_URL + WeatherAPIConstants.DATA_SUBDIRECTORY
        
        let appendApiVersion = baseUrlWithDataDirectory + WeatherAPIConstants.API_VERSION
        
        let appendWeatherPath = appendApiVersion + WeatherAPIConstants.WEATHER_PATH
        
        let urlAppendLatitude = appendWeatherPath + "?" +
        WeatherAPIConstants.LATITTUDE_PARAMETER + "=" + String(latitude)
        
        let urlAppendLongitude = urlAppendLatitude + "&" + WeatherAPIConstants.LONGITUDE_PARAMETER + "=" + String(longitude)
        
        let urlAppendApiKey = urlAppendLongitude + "&" + WeatherAPIConstants.API_KEY_PARAMETER + "=" + APIKeyProvider.getApiKey()
        
        print("Returning URL: " + urlAppendApiKey)
        
        return URL(string: urlAppendApiKey)
    }
    
    @IBAction func onChangeCityButtonClicked() {
        var alertController = UIAlertController(title: "City", message: "", preferredStyle: .alert)
        alertController.addTextField()
        var textField = alertController.textFields?.first
        textField?.placeholder = cityName
        var changeCityAction = UIAlertAction(title: "Change", style: .default) { UIAlertAction in
            var cityText = textField?.text
            
            if(cityText == nil && ((cityText?.isEmpty) != nil)) {
                return
            }
            
            self.EXTERNAL_ARGUMENT_originatedFromHome = false
            self.preinitialization(city: textField!.text!)
        }
        
        var cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        
        alertController.addAction(changeCityAction)
        alertController.addAction(cancelAction)
        present(alertController, animated:true)
    }
    
    //Requests weather information from OpenWeather API. Please view APIConstants to modify the call
    func startGetWeatherInfoDataTask(url : URL){
        
        let urlSession = URLSession(configuration: .default)
        
        let dataTask = urlSession.dataTask(with: url) {
            (data, response, error) in
            do {
                guard let data = data else { return }
                print("Entire JSON Response: " + String(data: data, encoding: .utf8)!)
                let parsedResponse = try JSONDecoder().decode(OpenWeatherJsonRoot.self, from: data)
                
                //This will run the code in main thread
                Task.detached { @MainActor in
                    self.updateUi(jsonRoot : parsedResponse)
                }
            } catch {
                print("Something went wrong while parsing.")
            }
        }
        
        dataTask.resume()
    }
    
    func updateUi(jsonRoot : OpenWeatherJsonRoot) {
        
        print("Updating UI from received json data.")
        
        reloadView?.removeFromSuperview()
        reloadView = nil
        
        self.cityLabel.text = cityName
        
        let optionalTemperature = jsonRoot.main?.temp
        if optionalTemperature != nil {
            let temperature = convertKelvinToCelcius(optionalTemperature!)
            let temperatureFormatted = String(format: "%.2f°C", temperature)
            temperatureLabel.text = temperatureFormatted
        } else { temperatureLabel.text = "~" }
        
        weatherLabel.text = ((jsonRoot.weather?.first?.main)!) + ". " + capitalizeFirstLetter((jsonRoot.weather?.first?.description)!)
        
        weatherType = WeatherAPIConstants.getWeatherTypeFromId( jsonRoot.weather?.first?.id)
        
        if(jsonRoot.main?.humidity == nil) {
            humidityLabel.text = "~"
        } else {
            var humidityStr = String(format: "%.2d", jsonRoot.main!.humidity!)
            humidityLabel.text = humidityStr + "% Humidity"
        }
        
        var windSpeedMps = jsonRoot.wind?.speed
        var windSpeedKphStrFormatted = convertMeterPerSecondToKmPerHour(mpsValue: windSpeedMps)
        
        windSpeedLabel.text = windSpeedKphStrFormatted
        
        print(weatherType)
        
        startAnimations()
    }

    
    func convertKelvinToCelcius(_ kelvinValue : Double) -> Float {
        return Float(kelvinValue - WeatherAPIConstants.KELVIN_TO_CELCIUS_DIFFERENCE)
    }
    
    func capitalizeFirstLetter(_ str : String) -> String {
        var secondIndex = str.index(after: str.startIndex)
        return str[str.startIndex..<secondIndex].uppercased() +
        str[secondIndex..<str.endIndex].lowercased() + "."
    }
    
    //If adding new views, do not forget to set them to nil. Otherwise big memory leaks will occur.
    func hideAllViews() {
        cityLabel.layer.opacity = 0
        
        windSpeedLabel.layer.opacity = 0
        windSpeedView?.layer.opacity = 0
        windSpeedView?.removeFromSuperview()
        windSpeedView = nil
        
        humidityLabel.layer.opacity = 0
        humidityView?.layer.opacity = 0
        humidityView?.removeFromSuperview()
        humidityView = nil
        
        temperatureLabel.layer.opacity = 0
        temperatureView?.layer.opacity = 0
        temperatureView?.removeFromSuperview()
        temperatureView = nil
        
        weatherLabel.layer.opacity = 0
        weatherView?.layer.opacity = 0
        weatherView?.removeFromSuperview()
        weatherView = nil
        
        searchView?.layer.opacity = 0
        searchView?.layer.opacity = 0
        searchView?.removeFromSuperview()
        searchView = nil
    }
    
    //Not only animates the existing views but introduces many views and a reload button
    func startAnimations() {
        
        //MARK: Ideas to improve the function
        
        class AnimationValues {
            var duration : Float = 0.0
            var delayBefore : Float = 0.0
            var delayAfter : Float = 0.0
            
            init(_ duration : Float,  _ delayBefore : Float, _ delayAfter : Float) {
                self.duration = duration
                self.delayBefore = delayBefore
                self.delayAfter = delayAfter
            }
            
            func getTotalDurationAfter() -> Double {
                return Double(duration + delayAfter)
            }
        }
        
        var loadingViewAnimValues = AnimationValues(2, 0, 0)
        var cityLabelAnimValues = AnimationValues(2, 0.5, 1)
        var weatherImageValues = AnimationValues(0.5, 0, 0)
        var weatherLabelValues = AnimationValues(0.50, 0, 1)
        var temperatureLabelValues = AnimationValues(1, 0, 0)
        var temperatureViewValues = AnimationValues(0.5, 0, 1)
        var humidityLabelValues = AnimationValues(0.50, 0, 0)
        var humidityViewValues = AnimationValues(0.50, 0, 0)
        var windSpeedLabelValues = AnimationValues(0.50, 0, 0)
        var windSpeedViewValues = AnimationValues(0.50, 0, 0)
        var reloadButtonValues = AnimationValues(0.25, 0, 0)
        
        Task {
            
            var loadingViewStartY = loadingView.frame.origin.y
            var loadingViewEndY = UIScreen.main.bounds.height + loadingView.frame.height
            animateViewVertically(view: loadingView, startY: loadingViewStartY, endY: loadingViewEndY, duration: loadingViewAnimValues.duration)
            animateViewOpacity(view: loadingView, targetOpacity: 0, duration: loadingViewAnimValues.duration * 0.95)
            
            var cityLabelEndY = cityLabel.frame.origin.y
            var cityLabelStartY = -cityLabel.frame.height - 75
            
            animateViewVertically(
                view: cityLabel,
                startY: cityLabelStartY,
                endY: cityLabelEndY,
                duration: cityLabelAnimValues.duration)
            
            try await Task.sleep(nanoseconds: convertDoubleToNanoSeconds(cityLabelAnimValues.getTotalDurationAfter()))
            
            weatherView = getLottieAnimationView(animationName: weatherType.rawValue)
            
            print(weatherView.frame.origin.x)
            
            var weatherViewStartX = UIScreen.main.bounds.width / 2 - weatherView.frame.width / 2
            let weatherViewStartY = UIScreen.main.bounds.height
            var weatherViewEndY =  UIScreen.main.bounds.height - weatherView.frame.height
           
            weatherView.layer.frame = CGRect(x: weatherViewStartX, y: weatherViewStartY, width:200, height:200)
            
            animateViewVertically(
                view: weatherView,
                startY: weatherViewStartY,
                endY: weatherViewEndY,
                duration: weatherImageValues.duration)
            
            try await Task.sleep(nanoseconds: convertDoubleToNanoSeconds(weatherImageValues.getTotalDurationAfter()))
            
            var weatherLabelStartY =  -weatherLabel.frame.height
            
            var weatherLabelEndY =  weatherLabel.frame.origin.y
            
            var weatherLabelStartX = weatherLabel.frame.origin.x
            
            weatherLabel.layer.frame = CGRect(x: weatherLabelStartX, y: weatherLabelStartY, width:weatherLabel.frame.width, height:weatherLabel.frame.height)
            
            animateViewVertically(
                view: weatherLabel,
                startY: weatherLabelStartY,
                endY: weatherLabelEndY,
                duration: weatherLabelValues.duration)
            
            try await Task.sleep(nanoseconds: convertDoubleToNanoSeconds(weatherLabelValues.getTotalDurationAfter()))
            
            var temperatureLabelStartX = UIScreen.main.bounds.width + temperatureLabel.frame.width
            var temperatureLabelEndX = temperatureLabel.frame.origin.x
            
            animateViewHorizontally(view: temperatureLabel,
                                    startX: temperatureLabelStartX,
                                    endX: temperatureLabelEndX,
                                    duration: temperatureLabelValues.duration)
            
            temperatureView = getLottieAnimationView(animationName: "ANIMATION_TEMPERATURE")
            var temperatureViewHeight = temperatureLabel.frame.height * 2
            var temperatureViewWidth = temperatureViewHeight
            
            var temperatureViewStartX = temperatureLabel.frame.origin.x - temperatureViewWidth
            
            var temperatureViewStartY = -temperatureViewHeight
            var temperatureViewEndY = temperatureLabel.frame.origin.y - (temperatureViewHeight/2) + (temperatureLabel.frame.height / 2)
                        
            temperatureView.layer.frame = CGRect(
                x: temperatureViewStartX,
                y: temperatureViewStartY,
                width: temperatureViewWidth,
                height: temperatureViewHeight)
            
            animateViewVertically(
                view: temperatureView,
                startY: temperatureViewStartY,
                endY: temperatureViewEndY,
                duration: temperatureViewValues.duration)
            
            try await Task.sleep(nanoseconds: convertDoubleToNanoSeconds(temperatureViewValues.getTotalDurationAfter()))
            
            humidityView = getLottieAnimationView(animationName: "ANIMATION_HUMIDITY")
            var humidityViewWidth = CGFloat(150)
            var humidityViewHeight = CGFloat(150)
            
            var humidityViewStartX = -humidityViewWidth
            var humidityViewEndX = 0
            var humidityViewStartY = humidityLabel.frame.origin.y  - (humidityViewHeight)
            
            humidityView.layer.frame = CGRect(x: humidityViewStartX, y: humidityViewStartY, width: humidityViewWidth, height: humidityViewHeight)
            
            animateViewHorizontally(view: humidityView, startX: CGFloat(humidityViewStartX), endX: CGFloat(humidityViewEndX), duration: humidityViewValues.duration)
            
            var humidityLabelStartX = -humidityLabel.frame.width
            var humidityLabelEndX = humidityLabel.frame.origin.x
            
            animateViewHorizontally(view: humidityLabel, startX: humidityLabelStartX, endX: humidityLabelEndX, duration: humidityLabelValues.duration)
                        
            windSpeedView = getLottieAnimationView(animationName: "ANIMATION_WINDSPEED")
            var windSpeedViewWidth = CGFloat(150)
            var windSpeedViewHeight = CGFloat(150)
            
            var windSpeedViewStartX = UIScreen.main.bounds.width + windSpeedViewWidth
            var windSpeedViewEndX = UIScreen.main.bounds.width - windSpeedViewWidth
            var windSpeedViewStartY = windSpeedLabel.frame.origin.y  - (windSpeedViewHeight)
            
            windSpeedView.layer.frame = CGRect(x: windSpeedViewStartX, y: windSpeedViewStartY, width: windSpeedViewWidth, height: windSpeedViewHeight)
            
            animateViewHorizontally(view: windSpeedView, startX: CGFloat(windSpeedViewStartX), endX: CGFloat(windSpeedViewEndX), duration: windSpeedViewValues.duration)
            
            var windSpeedLabelStartX = UIScreen.main.bounds.width + windSpeedLabel.frame.width
            var windSpeedLabelEndX = windSpeedLabel.frame.origin.x
            
            animateViewHorizontally(view: windSpeedLabel, startX: windSpeedLabelStartX, endX: windSpeedLabelEndX, duration: windSpeedLabelValues.duration)
            
            
            try await Task.sleep(nanoseconds: convertDoubleToNanoSeconds(windSpeedLabelValues.getTotalDurationAfter()))
            
            reloadView = getLottieAnimationView(animationName: "ANIMATION_RELOAD")
            reloadView.stop()
            let reloadViewWidth = CGFloat(64)
            let reloadViewHeight = CGFloat(64)
            
            let reloadViewStartX = UIScreen.main.bounds.width - reloadViewWidth - 15
            let reloadViewEndY = UIScreen.main.bounds.height - reloadViewHeight - 15
            let reloadViewStartY = UIScreen.main.bounds.height + reloadViewHeight
            
            reloadView.layer.frame = CGRect(x: reloadViewStartX, y: reloadViewStartY, width: reloadViewWidth, height: reloadViewHeight)

            animateViewVertically(view: reloadView, startY: reloadViewStartY, endY: reloadViewEndY, duration: reloadButtonValues.duration)
            
            searchView = getLottieAnimationView(animationName: "ANIMATION_SEARCH")
            let searchViewWidth = CGFloat(64)
            let searchViewHeight = CGFloat(64)
            
            let searchViewStartX = CGFloat(15)
            let searchViewEndY = UIScreen.main.bounds.height - searchViewHeight - 15
            let searchViewStartY = UIScreen.main.bounds.height + searchViewHeight
            
            searchView.layer.frame = CGRect(x: searchViewStartX, y: searchViewStartY, width: searchViewWidth, height: searchViewHeight)

            animateViewVertically(view: searchView, startY: searchViewStartY, endY: searchViewEndY, duration: reloadButtonValues.duration)
            
            DispatchQueue.main.async {
                self.reloadButtonCreated()
                self.searchButtonCreated()
            }
        }
    }
    
    func reloadButtonCreated () {
        reloadView.isUserInteractionEnabled = true
        reloadView.addGestureRecognizer(reloadButtonClickTapGesture)
    }
    
    func searchButtonCreated() {
            searchView.isUserInteractionEnabled = true
            searchView.addGestureRecognizer(reloadButtonClickTapGesture)
    }
    
    
    @objc func onReloadButtonClicked(_ sender: UITapGestureRecognizer) {
        if currentlyReloadingData {
            return
        }
        
        initialize()
    }
    
    @objc func onSearchButtonClicked(_ sender: UITapGestureRecognizer) {
        onChangeCityButtonClicked()
    }
    
    func showLoadingView() {
        loadingView = getLottieAnimationView(animationName: loadingAnimationName)
        
        var loadingViewWidth = 200
        var loadingViewHeight = 200
        var loadingViewStartX = Int(UIScreen.main.bounds.width) / 2 - loadingViewWidth / 2
        var loadingViewStartY = Int(UIScreen.main.bounds.height) / 2 - loadingViewHeight / 2
        
        loadingView.layer.frame = CGRect(
            x: loadingViewStartX,
            y: loadingViewStartY,
            width: loadingViewWidth,
            height: loadingViewHeight)
    }

    
    func animateViewVertically (view : UIView,
        startY : CGFloat,
        endY : CGFloat,
        duration : Float) {
        view.frame.origin.y = startY
        
        let snappyTimingFunction = CAMediaTimingFunction(controlPoints: 0.5, 0.0, 0.5, 1.0)
        CATransaction.begin()
        CATransaction.setAnimationDuration(CFTimeInterval(duration))
        CATransaction.setAnimationTimingFunction(snappyTimingFunction)
        
        UIView.animate(
            withDuration: TimeInterval(duration),
            delay: 0,
            options: .curveLinear)
        {
            view.layer.opacity = 1
            view.frame.origin.y = endY
        }
        
        CATransaction.commit()
    }
    
    func animateViewHorizontally (view : UIView,
        startX : CGFloat,
        endX : CGFloat,
        duration : Float) {
        
        let snappyTimingFunction = CAMediaTimingFunction(controlPoints: 0.5, 0.0, 0.5, 1.0)
        CATransaction.begin()
        CATransaction.setAnimationDuration(CFTimeInterval(duration))
        CATransaction.setAnimationTimingFunction(snappyTimingFunction)
        
        view.frame.origin.x = startX
        UIView.animate(
            withDuration: TimeInterval(duration),
            delay: 0,
            options: .curveLinear)
        {
            view.layer.opacity = 1
            view.frame.origin.x = endX
        }
        
        CATransaction.commit()
    }
    
    func animateViewOpacity(view : UIView, targetOpacity : Float, duration: Float) {
        UIView.animate(
            withDuration: TimeInterval(duration),
            delay: 0,
            options: .curveEaseIn)
        {
            view.layer.opacity = targetOpacity
        }
    }
    
    func getLottieAnimationView(animationName : String) -> LottieAnimationView {
        var animationView = LottieAnimationView.init(name: animationName)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.play()
        view.addSubview(animationView)
        return animationView
    }
    
    func convertDoubleToNanoSeconds(_ value : Double) -> UInt64 {
        return UInt64( value * Double(NSEC_PER_SEC))
    }
    
    func convertMeterPerSecondToKmPerHour(mpsValue : Double?) -> String{
        if mpsValue == nil {
            return "~"
        }
        
        return String(format: "%.2f km/h",
                      Float(mpsValue!) * Float(WeatherAPIConstants.MULTIPLY_BY_THIS_FOR_MPS_TO_KMH))
    }
}

