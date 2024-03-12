//
//  HistoryViewController.swift
//  Kashif_Kadri_FE_8866889
//
//  Created by AK on 2023-12-01.
//

import UIKit
import CoreData

class HistoryViewController: UITableViewController {
    let DID_POPULATE_HISTORY_ALREADY_KEY = "didPopulateHistoryAlready"
    @IBOutlet var _tableView : UITableView!
    
    var historyEntities : Array<HistoryEntity> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _tableView.delegate = self
        _tableView.dataSource = self
        
        populateHistoryIfNotAlready()
        
        fetchHistoryEntities()
        tableView.reloadData()
        // Do any additional setup after loading the view.
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        historyEntities.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = _tableView.dequeueReusableCell(withIdentifier: "reusable_history_item", for: indexPath) as! HistoryTableViewCell?

        var currentHistoryEntity = historyEntities[indexPath.row]
        
        if indexPath.row % 2 == 0 {
            cell?.backgroundSuperview.backgroundColor = UIColor.systemBackground
        } else {
            cell?.backgroundSuperview.backgroundColor = UIColor.systemGray4
        }
        
        cell?.interactionLabel.text  = currentHistoryEntity.interactionName
        cell?.originLabel.text  = currentHistoryEntity.originTabName
        cell?.interactionDateLabel.text = currentHistoryEntity
            .interactionTime?
            .getFormattedDate(format:"yyyy-MM-dd HH:mm:ss")
        
        switch(currentHistoryEntity.interactionName) {
            
        case TabNames.MAPS.rawValue: return populateMapsCell(cell: cell, index: indexPath.row)!
            
        case TabNames.NEWS.rawValue: return populateNewsCell(cell: cell, index: indexPath.row)!
            
        case TabNames.WEATHER.rawValue: return populateWeatherCell(cell: cell, index: indexPath.row)!
            
            
        default: return cell!
            
        }
    }
    
    /*
    //TODO: Fix this dynamic height when time
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if(cellsUpdated) {
            var cell =  tableView.cellForRow(at: indexPath) as! HistoryTableViewCell
            return 200 + cell.infoValue1Label.frame.height + cell.infoValue2Label.frame.height + cell.infoValue3Label.frame.height
        }
        
        return 200
    }
     */
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var currentEntity = historyEntities[indexPath.row]
        var forInteraction = currentEntity.interactionName
      
        
        if(forInteraction == TabNames.NEWS.rawValue){
            //An assumption is made
            //3 pixels for every 1 character
            var titleCharCount = (currentEntity.newsEntity?.title?.count ?? 0)
            var contentCharCount = (currentEntity.newsEntity?.story?.count ?? 0)
            
            print("charcounts: " + String(titleCharCount + contentCharCount))
            return CGFloat((titleCharCount + contentCharCount)) * 3
        } else { return 170 }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 170
    }
    
    func populateMapsCell(cell : HistoryTableViewCell?, index : Int) -> HistoryTableViewCell? {
        cell?.cityLabel.text = historyEntities[index].mapEntity?.originCity
        
        cell?.infoKey1Label.text = "From"
        cell?.infoValue1Label.text = historyEntities[index].mapEntity?.originCity
        
        cell?.infoKey2Label.text = "To"
        cell?.infoValue2Label.text = historyEntities[index].mapEntity?.destinationCity
        
        cell?.infoKey3Label.text = "Travel mode"
        cell?.infoValue3Label.text = historyEntities[index].mapEntity?.travelMode
        
        return cell
    }
    
    func populateNewsCell(cell : HistoryTableViewCell?, index : Int) -> HistoryTableViewCell? {
        cell?.cityLabel.text = historyEntities[index].locationCoordsEntity?.cityName
        
        var article = historyEntities[index].newsEntity
        
        cell?.infoKey1Label.text = "Title"
        cell?.infoValue1Label.text = article?.title
        
        cell?.infoKey2Label.text = "Content"
        cell?.infoValue2Label.text = article?.story
        
        cell?.infoKey3Label.text = "Author"
        cell?.infoValue3Label.text =  (article?.author ?? "Anonymous") + ", " + (article?.source ?? "Unknown")
        
        return cell
    }
    
    func populateWeatherCell(cell : HistoryTableViewCell?, index : Int) -> HistoryTableViewCell? {
        cell?.cityLabel.text = historyEntities[index].locationCoordsEntity?.cityName
        
        var weather = historyEntities[index].weatherEntity
        
        cell?.infoKey1Label.text = "Temperature"
        cell?.infoValue1Label.text = weather?.temperatureCelcius
        
        cell?.infoKey2Label.text = "Windspeed"
        cell?.infoValue2Label.text = weather?.windSpeedKmh
        
        cell?.infoKey3Label.text = "Humidity"
        cell?.infoValue3Label.text =  weather?.humidityPercentage
        
        return cell
    }
    
    //Fetch history entities from CoreData's persistence context
    func fetchHistoryEntities() {
        historyEntities = CoreDataUtils.getUpdatedHistoryEntities()!
        historyEntities.reverse()
    }
    
    
    //Delete all history entities from db, array and refersh tableview
    @IBAction func deleteAllHistories() {
        var databaseContextLayer = CoreDataUtils.databaseContextLayer
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "HistoryEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        do
        {
            try databaseContextLayer.execute(deleteRequest)
            try databaseContextLayer.save()
            historyEntities.removeAll()
            _tableView.reloadData()

        }
        catch
        {
            print ("There was an error")
        }
    }
    
   override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
       if editingStyle == .delete {
           CoreDataUtils.deleteHistory(entity: historyEntities[indexPath.row])
           historyEntities.remove(at: indexPath.row)
           _tableView.deleteRows(at: [indexPath], with: .fade)
       }
   }
    
    func populateHistoryIfNotAlready() {
        let preferences = UserDefaults.standard

        if preferences.object(forKey: DID_POPULATE_HISTORY_ALREADY_KEY) == nil {
            
            populateHistoryWithDummyData()
            
        } else {
            
            let historyPopulated = preferences.bool(forKey: DID_POPULATE_HISTORY_ALREADY_KEY)
            
            if(!historyPopulated) { populateHistoryWithDummyData() }
        }
    }
    
    func populateHistoryWithDummyData() {
        
        let preferences = UserDefaults.standard
        preferences.set(true, forKey: DID_POPULATE_HISTORY_ALREADY_KEY)
        
        // MARK: Dummy news 1
        var newsHistoryEntity1 = HistoryEntity(context: CoreDataUtils.databaseContextLayer)
        newsHistoryEntity1.historyId = UUID()
        newsHistoryEntity1.interactionName = TabNames.NEWS.rawValue
        newsHistoryEntity1.interactionTime = Date.now
        newsHistoryEntity1.originTabName = TabNames.NEWS.rawValue

        var newsEntity1 = NewsEntity(context: CoreDataUtils.databaseContextLayer)
        newsEntity1.newsId = UUID()
        newsEntity1.author = "John Doe"
        newsEntity1.title = "Breaking News: Dummy News 1"
        newsEntity1.story =  "This is the content of the dummy news article. It can be a longer story or just a brief summary."
        newsEntity1.source = "Dummy News Source 1"
        newsHistoryEntity1.newsEntity = newsEntity1

        // MARK: Dummy maps 1
        var mapsHistoryEntity1 = HistoryEntity(context: CoreDataUtils.databaseContextLayer)
        mapsHistoryEntity1.historyId = UUID()
        mapsHistoryEntity1.interactionName = TabNames.MAPS.rawValue
        mapsHistoryEntity1.interactionTime = Date.now
        mapsHistoryEntity1.originTabName = TabNames.MAPS.rawValue

        var mapsEntity1 = MapEntity(context: CoreDataUtils.databaseContextLayer)
        mapsEntity1.mapId = UUID()
        mapsEntity1.originCity = "Hamilton"
        mapsEntity1.destinationCity = "Waterloo"
        mapsEntity1.totalDistanceTravelledMph = "120"
        mapsEntity1.travelMode = "Automobile"
        mapsHistoryEntity1.mapEntity = mapsEntity1

        // MARK: Dummy weather 1
        var weatherHistoryEntity1 = HistoryEntity(context: CoreDataUtils.databaseContextLayer)
        weatherHistoryEntity1.historyId = UUID()
        weatherHistoryEntity1.interactionName = TabNames.WEATHER.rawValue
        weatherHistoryEntity1.interactionTime = Date.now
        weatherHistoryEntity1.originTabName = TabNames.WEATHER.rawValue

        var weatherEntity1 = WeatherEntity(context: CoreDataUtils.databaseContextLayer)
        weatherEntity1.weatherId = UUID()
        weatherEntity1.weatherTitle = "Sunny Day"
        weatherEntity1.weatherDescription = "Clear sky with a gentle breeze"
        weatherEntity1.temperatureCelcius = "25"
        weatherEntity1.windSpeedKmh = "10"
        weatherEntity1.humidityPercentage = "50"
        weatherHistoryEntity1.weatherEntity = weatherEntity1

        // MARK: Dummy news 2
        var newsHistoryEntity2 = HistoryEntity(context: CoreDataUtils.databaseContextLayer)
        newsHistoryEntity2.historyId = UUID()
        newsHistoryEntity2.interactionName = TabNames.NEWS.rawValue
        newsHistoryEntity2.interactionTime = Date.now
        newsHistoryEntity2.originTabName = TabNames.NEWS.rawValue

        var newsEntity2 = NewsEntity(context: CoreDataUtils.databaseContextLayer)
        newsEntity2.newsId = UUID()
        newsEntity2.author = "Jane Smith"
        newsEntity2.title = "Special Report: Dummy News 2"
        newsEntity2.story =  "Dummy news Story 2"
        newsEntity2.source = "Dummy News Source 2"
        newsHistoryEntity2.newsEntity = newsEntity2

        // MARK: Dummy maps 2
        var mapsHistoryEntity2 = HistoryEntity(context: CoreDataUtils.databaseContextLayer)
        mapsHistoryEntity2.historyId = UUID()
        mapsHistoryEntity2.interactionName = TabNames.MAPS.rawValue
        mapsHistoryEntity2.interactionTime = Date.now
        mapsHistoryEntity2.originTabName = TabNames.MAPS.rawValue

        var mapsEntity2 = MapEntity(context: CoreDataUtils.databaseContextLayer)
        mapsEntity2.mapId = UUID()
        mapsEntity2.originCity = "Waterloo"
        mapsEntity2.destinationCity = "Guelph"
        mapsEntity2.totalDistanceTravelledMph = "150"
        mapsEntity2.travelMode = "Motorcycle"
        mapsHistoryEntity2.mapEntity = mapsEntity2

        // MARK: Dummy weather 2
        var weatherHistoryEntity2 = HistoryEntity(context: CoreDataUtils.databaseContextLayer)
        weatherHistoryEntity2.historyId = UUID()
        weatherHistoryEntity2.interactionName = TabNames.WEATHER.rawValue
        weatherHistoryEntity2.interactionTime = Date.now
        weatherHistoryEntity2.originTabName = TabNames.WEATHER.rawValue

        var weatherEntity2 = WeatherEntity(context: CoreDataUtils.databaseContextLayer)
        weatherEntity2.weatherId = UUID()
        weatherEntity2.weatherTitle = "Rainy Day"
        weatherEntity2.weatherDescription = "Heavy rain with thunderstorms"
        weatherEntity2.temperatureCelcius = "18"
        weatherEntity2.windSpeedKmh = "20"
        weatherEntity2.humidityPercentage = "80"
        weatherHistoryEntity2.weatherEntity = weatherEntity2

    }
}
