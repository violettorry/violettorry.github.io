import UIKit

class ViewController: UIViewController, UITableViewDataSource, UISearchBarDelegate, UISearchDisplayDelegate{
    
    @IBOutlet var Open: UIBarButtonItem!
    var toUrl = ""
    var toTitle = ""
    var nav_title = "Womanitely"
    @IBOutlet weak var search: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    var error: NSError?
    var search_t = Bool()
    var page = 1
    var url = ""
    var data = [Data]()
    var old_data = [Data]()
    var count = 1
    var ID = Int()
    let appDelegate:AppDelegate = UIApplication.sharedApplication().delegate! as! AppDelegate
    lazy   var searchBar:UISearchBar = UISearchBar(frame: CGRectMake(0, 0, 200, 20))
    @IBOutlet weak var rezult_label: UILabel!
    var category = String()
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    var title_analytics = ""
    @IBOutlet weak var main_title: UINavigationItem!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var reload_button: UIView!
    @IBOutlet weak var reloadButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.indicator.hidden = true
        reloadButton.layer.cornerRadius = 5
        let heightConstraint = search.constraints[0]
        self.revealViewController().rearViewRevealWidth = self.view.frame.size.width * 0.7
        Open.target = self.revealViewController()
        Open.action = #selector(SWRevealViewController.revealToggle(_:))
        self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        if((toTitle == "")||(toTitle == "Home")){
            title_analytics = "Home"
            main_title.title = "Womanitely"
        }else{
            title_analytics = toTitle
            main_title.title = toTitle
        }
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: title_analytics)
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject : AnyObject])
        heightConstraint.constant = 0
        self.search_t = false
        search.hidden = true
        reload_button.hidden = true
        view.makeToastActivityWithMessage(message: "Loading")
        dispatch_async(MyVariables.backgroundQueue, {
            if Reachability.isConnectedToNetwork() == false {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.reload_button.hidden = false
                    self.view.hideToastActivity()
                })
            }else{
                self.getJson(self.toUrl, page: self.page)
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
   
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if !MyVariables.close_menu{
            revealViewController().revealToggleAnimated(true)
        }
        view.endEditing(true)
    }
    
    //    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    //        if (scrollView.contentOffset.y < 0){
    //            print("Reached top.")
    //        }
    //        if (scrollView.contentOffset.y + scrollView.frame.size.height) >= scrollView.contentSize.height{
    //            print("Reached bottom.")
    //        }
    //    }
    
    @IBAction func reload(sender: UIButton) {
        reload_button.hidden = true
        if Reachability.isConnectedToNetwork() == false {
            self.reload_button.hidden = false
        }else{
            view.makeToastActivityWithMessage(message: "Loading")
            dispatch_async(MyVariables.backgroundQueue, {
                self.getJson(self.toUrl, page: self.page)
            })
        }
    }
    
    func getJson(url: String, page: Int){
        
        var nsuurl = NSURL()
        let pages = String(page)
        if search_t{
            let stringUrl = "http://womanitely.com/api/get_search_results_app/?search=" + url + "&count=7&page=" + pages
            nsuurl = NSURL(string: stringUrl.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLFragmentAllowedCharacterSet())!)!
        }else{
            if (url == ""){
                nsuurl = NSURL(string: "http://womanitely.com/api/get_recent_posts_app/?count=7&page=" + pages)!
            }else{
                nsuurl = NSURL(string: "http://womanitely.com/api/get_category_posts_app/?category_slug=" + url + "&count=7&page=" + pages)!
            }
        }
        let json = NSData(contentsOfURL: nsuurl)
        if (json != nil){
            let boardsDictionary: NSDictionary = (try! NSJSONSerialization.JSONObjectWithData(json!, options: NSJSONReadingOptions.MutableContainers)) as! NSDictionary
            count = boardsDictionary["count"] as! Int
            if(count > 0){
                let jsonDate: NSMutableArray! = boardsDictionary["posts"] as! NSMutableArray
                for i in 0 ..< jsonDate.count{
                    var category = ""
                    let data = jsonDate[i] as! NSDictionary
                    let title = data["title"] as! String
                    let id = data["id"] as! Int
                    if ((url == "") && (i == 0) && (page == 1)) {
                        let id_l = data["id"] as! Int
                        let token = appDelegate.token as String
                        let dev_id = appDelegate.dev_id as String
                        let request = NSMutableURLRequest(URL: NSURL(string: "http://womanitely.com/app/json_parse.php")!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 5)
                        var response: NSURLResponse?
                        let time_zone = NSTimeZone.localTimeZone().name
                        let jsonString = "json={\"dev_id\":\"" + dev_id + "\",\"token\":\"" + token + "\",\"id\":\"" + String(id_l) + "\",\"time_zone\":\"" + String(time_zone) + "\",\"from\":\"\",\"to\":\"\",\"on_off\":\"\"}"
                        request.HTTPBody = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
                        request.HTTPMethod = "POST"
                        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                        do {
                            try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
                        } catch let error1 as NSError {
                            error = error1
                        } catch {
                        }
                    }
                    let dateString = data["date"] as! String
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.timeZone = NSTimeZone(abbreviation: "UTC");
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let date = dateFormatter.dateFromString(dateString)
                    let timeAgo:String = DateAgo().timeAgoSinceDate(date!, numericDates: true)
                    let categ: NSArray! = data["categories"] as! NSArray!
                    for j in 0 ..< categ.count{
                        var categor = (categ[j] as! NSDictionary)["title"] as! String
                        categor = categor.stringByReplacingOccurrencesOfString("&amp;", withString: "&", options: NSStringCompareOptions.LiteralSearch, range: nil)
                        if(j != 0){
                            category += ", "
                        }
                        category += categor
                    }
                    var img = String()
                    if (data["iosimage"] is NSNull){
                        img = ""
                    }else{
                        img = data["iosimage"] as! String
                        img = img.stringByReplacingOccurrencesOfString("’", withString: "%E2%80%99", options: NSStringCompareOptions.LiteralSearch, range: nil)
                        img = String(EncodedString: img)
                    }
                    let imgurl = NSURL(string: img)
                    let dataRecord = Data(name: title, imageUrl:imgurl!, category:category, date: timeAgo, id: id, status: "")
                    self.data.append(dataRecord)
                }
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
                self.view.hideToastActivity()
            })
        } else{
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.count = 1
                self.view.makeToast(message: "Network unavailable. Please, check your network settings and try again")
            })
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (search.text != "") && (data.count == 0) {
            rezult_label.hidden = false
            rezult_label.text = "Search results for \"" + search.text! + "\".\n Sorry, but you are looking for something that isn't here."
            rezult_label.sizeToFit()
            tableView.hidden = true
        }else if(data.count == 0){
            tableView.hidden = true
            rezult_label.hidden = true
        }else{
            tableView.hidden = false
            rezult_label.hidden = true
        }
        return data.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let dataDetails = data[indexPath.row]
        tableView.separatorColor = UIColor.clearColor()
        let cell = self.tableView.dequeueReusableCellWithIdentifier("cellTable", forIndexPath: indexPath) as! Table
        cell.layoutMargins = UIEdgeInsetsZero;
        cell.preservesSuperviewLayoutMargins = false
        cell.Title.layer.shadowRadius = 1.0
        cell.Title.layer.shadowOpacity = 1;
        cell.Title.layer.shadowOffset = CGSize.zero
        cell.Title.layer.masksToBounds = false
        cell.Category.layer.shadowRadius = 1.0
        cell.Category.layer.shadowOpacity = 1;
        cell.Category.layer.shadowOffset = CGSize.zero
        cell.Category.layer.masksToBounds = false
        cell.Date.layer.shadowRadius = 1.0
        cell.Date.layer.shadowOpacity = 1;
        cell.Date.layer.shadowOffset = CGSize.zero
        cell.Date.layer.masksToBounds = false
        cell.Title.text = String(htmlEncodedString: dataDetails.name)
        cell.Category.text = dataDetails.category
        cell.Date.text = dataDetails.date
        let height: CGFloat = 333
        let width: CGFloat = 500
        let scaleFactor: CGFloat = cell.frame.size.width / width
        let newHeight: CGFloat = height * scaleFactor;
        tableView.rowHeight = newHeight
        cell.imageUrl = dataDetails.imageUrl
        if let image = dataDetails.imageUrl.cachedImage {
            cell.imageView1.image = image
        } else {
            cell.imageView1?.image = UIImage(named: "Blank52")
            dataDetails.imageUrl.fetchImage { image in
                if cell.imageUrl == dataDetails.imageUrl {
                    cell.imageView1.image = image
                }
            }
        }
        self.indicator.hidden = true
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if (indexPath.row == data.count - 3 && count != 0){
            dispatch_async(MyVariables.backgroundQueue, {
                self.page = self.page + 1
                if (self.search_t){
                    self.getJson(self.url, page:self.page)
                }else{
                    self.getJson(self.toUrl, page: self.page)
                }
            })
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)) && (count == 0){
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.view.makeToast(message: "No more posts")
                self.indicator.hidesWhenStopped = true
            })
        }else if (scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)) && (count != 0){
            if (count < 7){
                self.indicator.hidden =  true
            }else{
                self.indicator.hidden =  false
                indicator.startAnimating()
            }
        }else{
            self.indicator.stopAnimating()
            self.indicator.hidesWhenStopped = true
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !MyVariables.close_menu{
            revealViewController().revealToggle(tableView)
        }else{
            self.performSegueWithIdentifier("segue", sender: nil)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!){
        if (segue.identifier == "segue") {
            let row = self.tableView.indexPathForSelectedRow!.row
            let svc = segue.destinationViewController as! SingleView
            svc.toId = data[row].id
            svc.favour = false
            svc.to_back = true
        }
    }
    
    func search(sender: AnyObject) {
        self.search.becomeFirstResponder()
        if(search_t == false){
            old_data = data
            nav_title = main_title.title!
        }
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Pad){
            heightConstraint.constant = 60
        }else{
            heightConstraint.constant = 44
        }
        self.search.hidden = false
        self.search_t = true
        MyVariables.close_menu = true
    }
    
    func searchBarSearchButtonClicked( searchBar: UISearchBar)
    {
        if Reachability.isConnectedToNetwork() == true {
            data = [Data]()
            reload_button.hidden = true
            main_title.title! = "Search"
            self.view.endEditing(true)
            let url_first = searchBar.text!
            self.view.makeToastActivityWithMessage(message: "Loading")
            page = 1
            dispatch_async(MyVariables.backgroundQueue, {
                self.getJson(url_first, page:1)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableView.setContentOffset(CGPointMake(0.0, 0.0), animated: false)
                    let tracker = GAI.sharedInstance().defaultTracker
                    tracker.set(kGAIScreenName, value: "Search: "+url_first)
                    let builder = GAIDictionaryBuilder.createScreenView()
                    tracker.send(builder.build() as [NSObject : AnyObject])
                })
            })
        } else {
            reload_button.hidden = true
            self.view.makeToast(message: "Network unavailable. Please, check your network settings and try again", duration: 2.0, position: "top")
        }
    }
    
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        if !MyVariables.close_menu{
            revealViewController().revealToggleAnimated(true)
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        self.view.endEditing(true)
        search.text = ""
        heightConstraint.constant = 0
        self.search_t = false
        search.hidden = true
        main_title.title = nav_title
        if(old_data.count != 0){
            data = old_data
            self.tableView.setContentOffset(CGPointMake(0.0, 0.0), animated: false)
            tableView.reloadData()
        }
    }
}
