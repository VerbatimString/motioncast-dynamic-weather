//
//  ArticleDetailViewController.swift
//  Kashif_Kadri_FE_8866889
//
//  Created by AK on 2023-12-03.
//

import UIKit

class ArticleDetailViewController: UIViewController {

    public var EXTERNAL_ARGUMENT_article : Article? = nil
    
    @IBOutlet var articleTitleLabel : UILabel!
    @IBOutlet var articleImageView : UIImageView!
    @IBOutlet var articleContentTextView : UITextView!
    @IBOutlet var authorshipInfo : UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if(EXTERNAL_ARGUMENT_article != nil) {
            updateUi(article: EXTERNAL_ARGUMENT_article!)
        } else {
            //TODO: Handle error
        }
    }
    
    func updateUi(article : Article) {
        articleTitleLabel.text = article.title
        articleImageView.setCustomImage(article.urlToImage)
        articleContentTextView.text = article.content
        authorshipInfo.text = getAuthorshipText(article: article)
    }
}
