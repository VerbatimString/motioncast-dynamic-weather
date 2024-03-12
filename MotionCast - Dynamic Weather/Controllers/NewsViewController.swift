//
//  NewsViewController.swift
//  Kashif_Kadri_FE_8866889
//
//  Created by AK on 2023-12-01.
//

import UIKit

class NewsViewController: UITableViewController {
    
    public var EXTERNAL_ARGUMENT_city : String = "Hamilton,ON"
    public var EXTERNAL_ARGUMENT_originatedFromHome = false
    
    @IBOutlet var articleTableView : UITableView!
    
    var newsArticles : Array<Article>? = []
    
    var queryName = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if(EXTERNAL_ARGUMENT_city.hasValidValue()) {
            queryName = EXTERNAL_ARGUMENT_city
            initialize(cityName: queryName)
        } else {
            //TODO: handle empty string
        }
    }
    
    func initialize(cityName : String) {
        articleTableView.delegate = self
        articleTableView.dataSource = self
        
        newsArticles?.removeAll()
        
        let url = getUrlTrendingArticlesInCity(city: cityName)
        handleTrendingArticlesInCityCall(optionalUrl: url)
    }
    
    //Constructs a URL for NewsAPI. Please view NewsConstants to modify the call
    func getUrlTrendingArticlesInCity(city : String!) -> URL? {
        
        let baseUrl =
        NewsAPIConstants.BASE_URL +
        NewsAPIConstants.API_VERSION +
        NewsAPIConstants.TOP_HEADLINES_DIRECTORY
        
        let urlAppendKeywordSearch = baseUrl + "?" + NewsAPIConstants.KEYWORD_PARAMETER + "=" + city
        
        let urlAppendApiKey = urlAppendKeywordSearch + "&" + NewsAPIConstants.API_KEY_PARAMETER + "=" + NewsAPIConstants.API_KEY
        
        print("NewsAPI URL generated: " + urlAppendApiKey)
        
        return URL(string: urlAppendApiKey)
    }
    
    
    //Make a call to the news api for trending cities with a query
    func handleTrendingArticlesInCityCall(optionalUrl: URL?) {
        
        if(optionalUrl == nil) {
            return
        }
        
        let url = optionalUrl!
        
        let urlSession = URLSession(configuration: .default)
        
        let dataTask = urlSession.dataTask(with: url) {
            (data, response, error) in
            
            do {
                guard let data = data else { return }
                print("Entire JSON Response: " + String(data: data, encoding: .utf8)!)
                
                var parsedResponse : NewsJsonRoot? = nil
                
                do {
                    parsedResponse = try JSONDecoder().decode(NewsJsonRoot.self, from: data)
                    print(parsedResponse)
                } catch {
                    print(error)
                }
                
                //This will run the code in main thread
                
                DispatchQueue.main.async {
                    self.updateUi(jsonRoot: parsedResponse)
                    self.saveHistoryEntity()
                }
            } catch {
                print("Something went wrong while parsing.")
            }
        }
        
        dataTask.resume()
    }
    
    
    //Update ui based on the supplied json root
    func updateUi(jsonRoot: NewsJsonRoot?) {
        print("Updating UI")
        newsArticles = jsonRoot?.articles
        articleTableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return newsArticles!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = articleTableView.dequeueReusableCell(withIdentifier: "newsArticle", for: indexPath) as! NewsTableViewCell?
        
        cell?.articleTitleLabel.text = newsArticles![indexPath.row].title
        cell?.articleDescriptionLabel.text = newsArticles![indexPath.row].content
        cell?.articleAuthorLabel.text = newsArticles![indexPath.row].author
        cell?.articleSourceLabel.text = newsArticles![indexPath.row].source?.name
        
        var remoteImageUrl = newsArticles![indexPath.row].urlToImage
        cell?.articleImageView.setCustomImage(remoteImageUrl)
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Row clicked: " + String(indexPath.row))
        gotoDetailedArticleViewController(articleDetails: newsArticles?[indexPath.row])
    }
    
    func gotoDetailedArticleViewController(articleDetails : Article?) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let controller = storyboard.instantiateViewController(withIdentifier: "ArticleDetailViewController") as? ArticleDetailViewController {
            // Optionally, you can pass data to the second view controller
            controller.EXTERNAL_ARGUMENT_article = articleDetails
            
            // Push the second view controller onto the navigation stack
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    
    //Instantiate appropriate alertcontroller and reinitialize when input is received
    @IBAction func onChangeCityButtonClick() {
        var alertController = UIAlertController(title: "Query", message: "", preferredStyle: .alert)
        alertController.addTextField()
        var textField = alertController.textFields?.first
        textField?.placeholder = queryName
        
        var changeCityAction = UIAlertAction(title: "Change", style: .default) { UIAlertAction in
            var cityText = textField?.text
            
            if(cityText == nil && ((cityText?.isEmpty) != nil)) {
                return
            }
            
            self.EXTERNAL_ARGUMENT_originatedFromHome = false
            self.queryName = cityText!
            self.initialize(cityName: self.queryName)
        }
        
        var cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        
        alertController.addAction(changeCityAction)
        alertController.addAction(cancelAction)
        present(alertController, animated:true)
    }
    
    
    //Saves a new history entity with appropriate news article relationship
    func saveHistoryEntity() {
        var historyEntity = HistoryEntity(context: CoreDataUtils.databaseContextLayer)
        historyEntity.interactionName = TabNames.NEWS.rawValue
        historyEntity.originTabName = EXTERNAL_ARGUMENT_originatedFromHome ? TabNames.MAIN.rawValue : TabNames.NEWS.rawValue
        historyEntity.interactionTime = Date.now
        var locationCoords = LocationCoordinatesEntity(context: CoreDataUtils.databaseContextLayer)
        locationCoords.cityName = queryName
        historyEntity.locationCoordsEntity = locationCoords
        var newsEntity = NewsEntity(context: CoreDataUtils.databaseContextLayer)
        
        if(newsArticles?.first ?? nil != nil) {
            newsEntity.title = newsArticles?.first?.title
            newsEntity.story = newsArticles?.first?.content
            newsEntity.author = getAuthorshipText(article: newsArticles!.first!)
            historyEntity.newsEntity = newsEntity
        }
        
        CoreDataUtils.save()
    }
}
