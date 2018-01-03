//
//  TableViewController.swift
//  ReportCamera
//
//  Created by tanaka.takaaki on 2017/02/06.
//  Copyright © 2017年 tanaka.takaaki. All rights reserved.
//

import Alamofire
import AlamofireImage
import Himotoki
import UIKit
import SwiftyJSON

public protocol Decodable {
    typealias DecodedType = Self
    
    /// - Throws: DecodeError
    static func decode(e: Extractor) throws -> DecodedType
}

struct Timeline {
    let iconURL: String?
    let name: String?
    let title: String?
    
    init(json: JSON) {
        iconURL = json["iconURL"].string
        name = json["name"].string
        title = json["title"].string
    }
}

class SessionCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var sessionNameLabel: UILabel!
    @IBOutlet weak var speakerNameLabel: UILabel!
    
    func fill(with timeline: Timeline) {
        if let urlString = timeline.iconURL {
            iconImageView.af_setImage(withURL: URL(string: urlString)!)
        }
        speakerNameLabel.text = timeline.name ?? ""
        sessionNameLabel.text = timeline.title ?? ""
    }
}

class TableViewController: UITableViewController {

    private var timelines: [Timeline] = [] {
        didSet {
            tableView?.reloadData()
        }
    }
    
    private var selectedIndexPath: IndexPath? = nil
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Camera" {
            if let vc = segue.destination as? CameraViewController {
                vc.timeline = timelines[selectedIndexPath!.row]
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(TableViewController.getTimeline(_:)), for: .valueChanged)
    }

    func getTimeline(_ sender: UIRefreshControl) {
        refreshControl?.beginRefreshing()
        Alamofire.request(URL(string: "https://xxxxxxxxxxxxx.cloudfront.net/timeline/timelines.json")!)
            .responseJSON { [weak self] response in
                self?.refreshControl?.endRefreshing()
                //print(response)
                
                switch response.result {
                case .success(let json):
                    print(json)
                    
                    let timelines = JSON(json)["timelines"].arrayValue
                    
                    //let timelines: [Timeline] = try! decodeArray(json) as! [Timeline]
                    
                    self?.timelines = timelines.map { Timeline(json: $0) }
                case .failure(let error):
                    print(error)
                }
                //print(response.request as Any)  // original URL request
                //print(response.response as Any) // URL response
                //print(response.result.value as Any)   // result of response serialization
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return timelines.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SessionCell", for: indexPath)

        guard let sessionCell = cell as? SessionCell else {
            return cell
        }
        
        sessionCell.fill(with: timelines[indexPath.row])
        
        // Configure the cell...

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        selectedIndexPath = indexPath
        
        performSegue(withIdentifier: "Camera", sender: nil)
    }

}
