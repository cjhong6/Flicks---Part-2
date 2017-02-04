
//  MCviewController.swift
//  MovieViewer
//
//  Created by Chengjiu Hong on 2/2/17.
//  Copyright © 2017 Chengjiu Hong. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MCviewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UISearchBarDelegate,UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchbar: UISearchBar!
    @IBOutlet weak var networkErrorButton: UIButton!
    
    var movies : [NSDictionary]? //actual data
    var filterMovies: [NSDictionary]? //represent rows of data that match our search text.
    var refreshControl: UIRefreshControl!
    var textSearch = "" //keep the search text
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        searchbar.delegate = self
        
        networkErrorButton.isHidden = true
        
        //Initialize a UIRefreshControl
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(MCviewController.refreshControlAction(sender:)), for: UIControlEvents.valueChanged)
        // add refresh control to table view
        collectionView.insertSubview(refreshControl, at: 0)
        
        makeAPICall()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        
        if let movies = filterMovies{
            return movies.count
        }else{
            return 0
        }
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCell", for: indexPath) as! MoviieCollectionViewCell //Downcast into MoviieCollectionViewCell class object
        
        let movie = filterMovies![indexPath.row] //get single movie
        
        let baseURL = "http://image.tmdb.org/t/p/w500"
        let posterPath = movie["poster_path"] as! String
        let imageURL = NSURL(string: baseURL + posterPath)
        let imageRequest = NSURLRequest(url: imageURL as! URL)

        //Fading in an Image Loaded from the Network
        cell.posterView.setImageWith(
            imageRequest as URLRequest,
            placeholderImage: nil,
            success: { (imageRequest, imageResponse, image) -> Void in
                
                // imageResponse will be nil if the image is cached
                if imageResponse != nil {
                    //print("Image was NOT cached, fade in image")
                    cell.posterView.alpha = 0.0
                    cell.posterView.image = image
                    UIView.animate(withDuration: 0.3, animations: { () -> Void in
                        cell.posterView.alpha = 1.0
                    })
                } else {
                    //print("Image was cached so just update the image")
                    cell.posterView.image = image
                }
        },
            failure: { (imageRequest, imageResponse, error) -> Void in
                // do something for the failure condition
        })
        
        //print ("row \(indexPath.row)")
        return cell
    }
    
    //When the search text changes we update filteredMovies and reload our table.
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // When there is no text, filterMovies is the same as the original movies
        // When user has entered text into the search box
        // Use the filter method to iterate over all movie in the movies array
        // For each movie, return true if the movie should be included and false if the
        // movie should NOT be included
        self.textSearch = searchText
        filterMovies = searchText.isEmpty ? movies : movies?.filter({(movie: NSDictionary) -> Bool in
            // If movie matches the searchText, return true to include it
            return (movie["title"] as! String).range(of: searchText, options: .caseInsensitive) != nil
        })
        collectionView.reloadData()
    }
    
    //refresh function call
    func refreshControlAction(sender:AnyObject) {
            makeAPICall()
            // Tell the refreshControl to stop spinning
            self.refreshControl.endRefreshing()
    }
    
    //click the network error button to make API call
    @IBAction func networkErrorBtnAction(_ sender: Any) {
        makeAPICall()
    }
    
    //show Cancel button when user taps on search bar
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchbar.showsCancelButton = true
    }
    
    //taps on cancel button: hide the Cancel button, keep existing text in search bar and hide the keyboard
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.text = self.textSearch
        searchBar.resignFirstResponder()
    }
    
    //Make API call
    func makeAPICall(){
        // ... Create the URLRequest `myRequest` ...
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = URL(string: "https://api.themoviedb.org/3/movie/now_playing?api_key=\(apiKey)")!
        
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        
        // Display HUD right before the request is made
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        // Configure session so that completion handler is executed on main UI thread
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
        // Hide HUD once the network request comes back (must be done on main UI thread)
        MBProgressHUD.hide(for: self.view, animated: true)
            
        // ... Use the new data to update the data source ...
        if let data = data {
                if let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    //print(dataDictionary)
                    self.movies = dataDictionary["results"] as? [NSDictionary]
                    self.filterMovies = self.movies
                    //Tableview is always get done before the network connection!!!!!
                    //MUST reload the tableview again after the network has been made
                    self.collectionView.reloadData()
                }
            }
            else{
                self.networkErrorButton.isHidden = false
            }
        }
        task.resume()
    }
    
    //space between left and right cell
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width:206.5, height: 281)
    }
    
    //space between up and down cell
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
 
    //space between up and down cell
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }

     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let cell = sender as! UICollectionViewCell
        let indexpath = collectionView.indexPath(for: cell)
        let movie = filterMovies?[(indexpath?.row)!]
        
        let detailViewController = segue.destination as! DetailViewController
        detailViewController.movie = movie
     }
 
}
