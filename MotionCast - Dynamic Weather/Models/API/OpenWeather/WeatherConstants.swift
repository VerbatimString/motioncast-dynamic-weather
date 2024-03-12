struct WeatherAPIConstants {
    /*
     MARK: Icon/Animation Credits
     App Icon - 'Free Pik' on Flaticon.com
     Humidity Icon - “Mr. Asadayut Amatayakul” on LottieFiles.com
     Thermometer Icon - “Animation Free” on LottieFiles.com
     All 8 Weather Icons - "Adriana Mandjarova” on LottieFiles.com
     */
    
    enum PossibleWeather: String {
        case UNKNOWN = "ANIMATION_UNKNOWN"
        case THUNDERSTORM = "ANIMATION_THUNDERSTORM"
        case DRIZZLE = "ANIMATION_DRIZZLE"
        case RAIN  = "ANIMATION_RAIN"
        case SNOW = "ANIMATION_SNOW"
        case ATMOSPHERE = "ANIMATION_FOGGY"
        case CLEAR = "ANIMATION_CLEAR"
        case CLOUDS = "ANIMATION_CLOUDY"
    }
    
    static let KELVIN_TO_CELCIUS_DIFFERENCE = 273.15
    static let MULTIPLY_BY_THIS_FOR_MPS_TO_KMH = 3.6
    
    static let BASE_URL : String = "https://api.openweathermap.org"
    static let DATA_SUBDIRECTORY : String  = "/data"
    static let API_VERSION : String  = "/2.5"
    static let WEATHER_PATH : String  = "/weather"
    static let LATITTUDE_PARAMETER = "lat"
    static let LONGITUDE_PARAMETER = "lon"
    static let API_KEY_PARAMETER = "appId"
    
    //MARK: First step, read the API documentation.
    //MARK: Identifying weather types
    static let THUNDERSTORM_WEATHER_ID_STARTS_WITH = "2"
    static let DRIZZLE_WEATHER_ID_STARTS_WITH = "3"
    static let RAIN_WEATHER_ID_STARTS_WITH = "5"
    static let SNOW_WEATHER_ID_STARTS_WITH = "6"
    static let ATMOSPHERE_WEATHER_ID_STARTS_WITH = "7"
    
    //MARK: Check clear weather before clouds
    static let CLEAR_WEATHER_ID_STARTS_WITH = "800"
    static let CLOUDS_WEATHER_ID_STARTS_WITH = "8"
    
    static func getWeatherTypeFromId (_ idInt : Int?) -> PossibleWeather {
        
        if(idInt == nil) { return PossibleWeather.UNKNOWN }
        
        var id = String(idInt!)
        
        var firstCharacter = id.prefix(1)
        var firstThreeCharacters = id.prefix(3)
        
        if(firstThreeCharacters == CLEAR_WEATHER_ID_STARTS_WITH) {
            return PossibleWeather.CLEAR
        }
        
        switch(firstCharacter) {
        case THUNDERSTORM_WEATHER_ID_STARTS_WITH: return PossibleWeather.THUNDERSTORM
        case DRIZZLE_WEATHER_ID_STARTS_WITH: return PossibleWeather.DRIZZLE
        case RAIN_WEATHER_ID_STARTS_WITH: return PossibleWeather.RAIN
        case SNOW_WEATHER_ID_STARTS_WITH: return PossibleWeather.SNOW
        case ATMOSPHERE_WEATHER_ID_STARTS_WITH: return PossibleWeather.ATMOSPHERE
        case CLOUDS_WEATHER_ID_STARTS_WITH: return PossibleWeather.CLOUDS
        default: return PossibleWeather.UNKNOWN
        }
    }
}
